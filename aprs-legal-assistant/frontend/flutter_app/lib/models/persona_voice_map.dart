// Maps persona roles to browser TTS voice names or indices.
// You can update these names to match those available in your browser.
// To see available voices, run in browser console: speechSynthesis.getVoices().forEach(v => console.log(v.name, v.lang));
const Map<String, String> personaVoiceMap = {
  'judge': 'Microsoft David Desktop - English (United States)', // Example Edge voice
  'lawyer': 'Microsoft Zira Desktop - English (United States)',
  'defendant': 'Google UK English Male',
  'witness': 'Google UK English Female',
};
