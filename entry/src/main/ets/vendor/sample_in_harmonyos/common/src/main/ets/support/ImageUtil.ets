export class ImageUtil {
  public static getImgResource(url?: string): ResourceStr {
    if (!url) {
      return $r('app.media.home_banner_ai_oral_practice');
    }
    if (url === 'home_banner_ai_oral_practice.png') {
      return $r('app.media.home_banner_ai_oral_practice');
    }
    if (url === 'home_banner_ai_study_file_converter.png') {
      return $r('app.media.home_banner_ai_study_file_converter');
    }
    if (url === 'home_banner_get_feedback.png') {
      return $r('app.media.home_banner_get_feedback');
    }
    if (url === 'home_banner_transform_notes_into_practice.png') {
      return $r('app.media.home_banner_transform_notes_into_practice');
    }
    const normalizedUrl: string = url.toLowerCase();
    if (normalizedUrl.startsWith('https://') || normalizedUrl.startsWith('http://')) {
      return url;
    }
    return $rawfile(url);
  }
}
