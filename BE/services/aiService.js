const { GoogleGenerativeAI } = require("@google/generative-ai");
const Category = require('../models/Category');
const SupportTicket = require('../models/SupportTicket');

// Defaulting to Google Gemini as the provider
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || 'mock-key');

async function processChat(req, res) {
  try {
    const { messages } = req.body;
    const userMessage = messages[messages.length - 1].content;
    const userId = req.user ? req.user.id : null;
    
    // Simulate RAG context building by fetching categories
    let contextData = "Our available service categories are: ";
    try {
      const categories = await Category.find({}).limit(5);
      contextData += categories.map(c => c.name).join(', ') + ". ";
    } catch (e) {
      contextData += "CCTV Installation, Networking, IT Services. ";
    }
    
    const systemPrompt = `You are the Techbes Smart Service Advisor. 
You act as a professional assistant for a field service marketplace (Techbes).
Context: \${contextData}
If a user needs help, suggest relevant services. 
If they have a complaint, offer to escalate to human support.
Be concise and helpful.`;

    // In a real production env, this streams response. Here we mock/invoke.
    if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY === 'mock-key') {
      // Mock Response Fallback
      return res.json({
        success: true,
        data: {
          reply: `I understand you need help with: "\${userMessage}". As a Smart Service Advisor, I can recommend exploring our CCTV or Networking packages based on your request. (Mock Mode Active)`
        }
      });
    }

    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    
    // Build history for Gemini
    const chat = model.startChat({
      history: [
        { role: "user", parts: [{ text: systemPrompt }] },
        { role: "model", parts: [{ text: "Understood. I am ready to assist." }] },
        ...messages.slice(0, -1).map(m => ({
          role: m.role === 'user' ? 'user' : 'model',
          parts: [{ text: m.content }]
        }))
      ]
    });

    const result = await chat.sendMessage(userMessage);
    const response = await result.response;
    
    res.json({
      success: true,
      data: { reply: response.text() }
    });

  } catch (error) {
    console.error("AI Service Error:", error);
    res.status(500).json({ success: false, message: 'Failed to process AI request', error: error.message });
  }
}

async function createAiTicketHandoff(req, res) {
  try {
    const { summary, chatLog } = req.body;
    
    const ticket = await SupportTicket.create({
      customer: req.user.id,
      subject: "AI Handoff: " + summary,
      category: "Other",
      priority: "Medium",
      messages: [{ sender: req.user.id, text: "Automated Handoff Log:\\n" + chatLog }]
    });

    res.status(201).json({ success: true, data: ticket });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = {
  processChat,
  createAiTicketHandoff
};
