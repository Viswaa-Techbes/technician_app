importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: 'AIzaSyBuk7-OvkXK4AYySDgvjO3eEByJvJ87w88',
  appId: '1:101794979262:web:7ca4824c51990fdb916def',
  messagingSenderId: '101794979262',
  projectId: 'techbes-app',
  authDomain: 'techbes-app.firebaseapp.com',
  storageBucket: 'techbes-app.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/favicon.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
