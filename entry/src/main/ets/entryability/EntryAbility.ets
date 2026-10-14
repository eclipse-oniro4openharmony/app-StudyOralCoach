import { AbilityConstant, ConfigurationConstant, UIAbility, Want, abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  async requestMicrophonePermission(): Promise<void> {
    const atManager = abilityAccessCtrl.createAtManager()
    const permissions: Permissions[] = ['ohos.permission.MICROPHONE']
    try {
      const result = await atManager.requestPermissionsFromUser(this.context as common.UIAbilityContext, permissions)
      if (result.authResults[0] !== 0) {
        hilog.error(DOMAIN, 'testTag', '%{public}s', 'Microphone permission denied')
      }
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to request microphone permission. Cause: %{public}s', JSON.stringify(err))
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    this.requestMicrophonePermission()

    windowStage.loadContent('pages/HomePage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      this.enableImmersiveWindow(windowStage);
    });
  }

  private async enableImmersiveWindow(windowStage: window.WindowStage): Promise<void> {
    try {
      const mainWindow = windowStage.getMainWindowSync();
      await mainWindow.setWindowLayoutFullScreen(true);
      await mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: '#FF111936',
        navigationBarContentColor: '#FF111936'
      });
      const systemAvoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      AppStorage.setOrCreate('immersiveSystemTopInsetPx', systemAvoidArea.topRect.height);
      hilog.info(DOMAIN, 'testTag', 'Immersive window layout enabled.');
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'Failed to enable immersive window layout. Cause: %{public}s',
        JSON.stringify(error));
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
