importScripts("https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAqeM4_hoxao7j6GTJ3Km1DuIqvDdbq1oM",
  appId: "1:359937070047:web:0a36cc7313ea81ac5d2a6a",
  messagingSenderId: "359937070047",
  projectId: "focusfox-cc167",
});

const messaging = firebase.messaging();
