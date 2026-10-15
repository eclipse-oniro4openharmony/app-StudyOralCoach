import type { ImageKnifeOption } from '@ohos/imageknife';
import { ImageUtil } from './ImageUtil';

export class ImageKnifeUtil {
  public static getImgOption(mediaUrl: string): ImageKnifeOption {
    return { loadSrc: ImageUtil.getImgResource(mediaUrl) };
  }
}
