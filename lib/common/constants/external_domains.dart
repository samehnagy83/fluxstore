part of '../constants.dart';

/// When opening an URL that includes these domains, it will open the external
/// app instead of the webview.
///
/// Moved to env.dart
const kExternalDomains = [
  'wa.me', // Whatsapp
  'wa.link', // Whatsapp
  'api.whatsapp.com', // Whatsapp
  'm.me', // Messenger
  'messenger.com', // Messenger
  'www.messenger.com', // Messenger
  'ig.me', // Instagram
  'instagram.com', // Instagram
  'www.instagram.com', // Instagram
  'x.com', // X
  'facebook.com', // Facebook
  'www.facebook.com', // Facebook
  'youtube.com', // Youbute
  'www.youtube.com', // Youbute
  'youtu.be', // Youbute
  't.me', // Telegram
  'telegram.org', // Telegram
  'play.google.com', // Google play
  'apps.apple.com', // App store
  'zalo.me', // Zalo
];

/// When opening an URL that start with these schemas, it will open the
/// non-browser external app instead of the webview or browser.
/// Also please check all queries in the files [AndroidManifest.xml] and
/// [Info.plist] if you use `canLaunchUrl` function
const kExternalNonBrowserDomains = [
  'tel:', // Phone call
  'sms:', // Send SMS
  'smsto:', // Send SMS
  'mailto:', // Send mail
  'skype:', // Skype
  'intent://', // Need to repace with scheme in the url
  'whatsapp://', // Whatsapp
  'instagram://', // Instagram
  'instagram-stories://', // Instagram story
  'twitter://', // Twitter
  'fb://', // Facebook
  'tg://', // Telegram
  'comgooglemaps://', // Google Maps
  'comgooglemapsurl://', // Google Maps URL
  'zalo://', // Zalo
  'fb-messenger:', // Facebook Messenger
  'viber:', // Viber
  'line:', // Line
  'zoommtg:', // Zoom Meeting
];
