export class UrlUtil {
  public static isNetUrl(url: string): boolean {
    if (typeof url !== 'string') {
      return false;
    }
    const lowerCaseUrl: string = url.toLowerCase();
    return lowerCaseUrl.startsWith('https://') || lowerCaseUrl.startsWith('http://');
  }
}
