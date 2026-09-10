export { getApiBaseUrl, PRODUCTION_API_URL, LOCAL_DEV_API_URL } from './api';

/**
 * Ensures Razorpay Checkout script is loaded on the page.
 */
export function loadRazorpayScript(): Promise<boolean> {
  return new Promise((resolve) => {
    if (typeof window === 'undefined') {
      resolve(false);
      return;
    }

    if ((window as any).Razorpay) {
      resolve(true);
      return;
    }

    const scriptId = 'razorpay-checkout-script';
    const existingScript = document.getElementById(scriptId);

    if (existingScript) {
      existingScript.addEventListener('load', () => resolve(true));
      existingScript.addEventListener('error', () => resolve(false));
      return;
    }

    const script = document.createElement('script');
    script.id = scriptId;
    script.src = 'https://checkout.razorpay.com/v1/checkout.js';
    script.async = true;

    script.onload = () => {
      resolve(true);
    };

    script.onerror = () => {
      console.error('Failed to load Razorpay checkout script.');
      resolve(false);
    };

    document.body.appendChild(script);
  });
}
