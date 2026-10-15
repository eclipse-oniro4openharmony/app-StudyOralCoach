import { deviceInfo } from '@kit.BasicServicesKit';

export class CommonConstants {
  public static readonly NAVIGATION_HEIGHT: number = 56;
  public static readonly TAB_BAR_WIDTH: number = 96;
  public static readonly SPACE_6: number = 6;
  public static readonly SPACE_8: number = 8;
  public static readonly SPACE_16: number = 16;
  public static readonly SPACE_32: number = 32;
  public static readonly ANIMATION_DURATION: number = 200;
}

@Observed
export class GlobalInfoModel {
  public widthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;
  public statusBarHeight: number = 0;
}

export class HdsUtil {
  public static isSupportNewMaterialApi(): boolean {
    return deviceInfo.distributionOSApiVersion >= 60100;
  }
}

export enum ProductSeriesEnum {
  VDE = 'VDE',
}

export enum StorageKey {
  GLOBAL_INFO = 'hmos_world_GlobalInfoModel',
  IS_SIDEBAR_LAYOUT = 'hmos_world_isSideBarLayout',
}

export interface BreakpointTypes<T> {
  xs?: T;
  sm: T;
  md: T;
  lg: T;
  xl?: T;
}

export class BreakpointType<T> {
  private xs: T;
  private sm: T;
  private md: T;
  private lg: T;
  private xl: T;

  public constructor(param: BreakpointTypes<T>) {
    this.xs = param.xs ?? param.sm;
    this.sm = param.sm;
    this.md = param.md;
    this.lg = param.lg;
    this.xl = param.xl ?? param.lg;
  }

  public getValue(currentBreakpoint: WidthBreakpoint): T {
    if (currentBreakpoint === WidthBreakpoint.WIDTH_XS) {
      return this.xs;
    }
    if (currentBreakpoint === WidthBreakpoint.WIDTH_SM) {
      return this.sm;
    }
    if (currentBreakpoint === WidthBreakpoint.WIDTH_MD) {
      return this.md;
    }
    if (currentBreakpoint === WidthBreakpoint.WIDTH_XL) {
      return this.xl;
    }
    return this.lg;
  }
}
