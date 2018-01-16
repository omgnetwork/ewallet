export default function copyToClipboard(text) {
  const textArea = document.createElement('textarea');
  textArea.value = text;
  document.body.appendChild(textArea);
  textArea.select();
  try {
    document.execCommand('copy');
  } catch (error) {
    console.log('Unable to copy'); //eslint-disable-line
  }
  document.body.removeChild(textArea);
}
