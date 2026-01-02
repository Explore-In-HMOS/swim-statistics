import sensor from '@ohos.sensor';
import common from '@ohos.app.ability.common';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import wantAgent, { WantAgent } from '@ohos.app.ability.wantAgent';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { SwimRecord } from '../model/SwimRecord';

@Component
struct Index {
  @State isRunning: boolean = false;
  @State elapsedMs: number = 0;
  @State strokeCount: number = 0;
  @State distanceMeters: number = 0;
  @State speed: number = 0;
  @Consume('navPathStack') navPathStack: NavPathStack;
  private intervalId: number = 0;
  private lastTime: number = 0;
  private distanceMultiplier = 0.5;
  private accelThreshold = 2;
  private lastStrokeTime = 0;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private bgTaskId: number = -1;
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  async aboutToAppear() {
    try {
      await this.dbHelper.initDatabase(this.context);
    } catch (err) {
      console.error('[Index] Database init error:', err);
    }
  }

  async start() {
    this.isRunning = true;
    this.lastTime = Date.now();

    this.intervalId = setInterval(() => {
      const now = Date.now();
      const dt = now - this.lastTime;
      this.lastTime = now;
      this.elapsedMs += dt;

      const elapsedSec = this.elapsedMs / 1000;
      this.speed = elapsedSec > 0 ? this.distanceMeters / elapsedSec : 0;
    }, 300) as number;

    await this.startContinuousTask();
    this.subscribeAccelerometer();
  }

  async stop() {
    this.isRunning = false;
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
      this.intervalId = -1;
    }
    this.unsubscribeAccelerometer();
    await this.stopContinuousTask();
  }

  reset() {
    this.elapsedMs = 0;
    this.strokeCount = 0;
    this.distanceMeters = 0;
    this.speed = 0;
    this.isRunning = false;
    this.unsubscribeAccelerometer();
  }

  async startContinuousTask() {

    try {
      let wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: this.context.abilityInfo.bundleName,
            abilityName: this.context.abilityInfo.name
          }
        ],
        //operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };

      const wantAgentObj: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);

      backgroundTaskManager.startBackgroundRunning(
        this.context,
        backgroundTaskManager.BackgroundMode.DATA_TRANSFER,
        wantAgentObj
      ).then(() => {
      }).catch((err: Error) => {
      });

    } catch (err) {
    }
  }

  async stopContinuousTask() {

    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context);
    } catch (err) {
    }
  }

  async saveWorkout() {
    if (this.strokeCount > 0) {
      try {
        const currentDate = new Date().toLocaleString('tr-TR');
        const durationMinutes = Math.round(this.elapsedMs / 60000);

        const newRecord = new SwimRecord(
          currentDate,
          durationMinutes,
          Math.round(this.distanceMeters),
          this.strokeCount
        );

        const rowId = await this.dbHelper.insertRecord(newRecord);

        this.getUIContext().showAlertDialog({
          title: 'Success',
          message: `Workout saved!\nStrokes: ${this.strokeCount}\nDistance: ${this.distanceMeters.toFixed(1)}m\nTime: ${durationMinutes} min`,
          confirm: {
            value: 'OK',
            action: () => {
            }
          }
        })

      } catch (err) {
        console.error('[Index] Error saving workout:', err);
        this.getUIContext().showAlertDialog({
          title: 'Error',
          message: 'Failed to save workout!',
          confirm: {
            value: 'OK',
            action: () => {
            }
          }
        });
      }
    } else {
      this.getUIContext().showAlertDialog({
        title: 'Warning',
        message: 'No workout data to save!',
        confirm: {
          value: 'OK',
          action: () => {
          }
        }
      });
    }
  }

  subscribeAccelerometer() {
    sensor.on(
      sensor.SensorId.ACCELEROMETER,
      (data) => {
        const magnitude = Math.sqrt(data.x * data.x + data.y * data.y);

        const now = Date.now();

        if (magnitude > this.accelThreshold &&
          now - this.lastStrokeTime > 800) {

          this.lastStrokeTime = now;
          this.strokeCount += 1;

          const dynamicDistance = magnitude * this.distanceMultiplier;
          this.distanceMeters += dynamicDistance;
        }
      },
      { interval: 200000000 }
    );
  }

  unsubscribeAccelerometer() {
    try {
      sensor.off(sensor.SensorId.ACCELEROMETER,);
    } catch (_) {
      console.error('[Index] Error stopping accelerometer');
    }
  }

  build() {
    NavDestination() {
      Column({ space: 2 }) {

        Text('Swim Statistics')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .margin({ top: 2, bottom: 2 })

        Column({ space: 10 }) {
          Text(`Time: ${(this.elapsedMs / 1000).toFixed(1)} s`)
            .fontSize(10)
            .fontColor('#000000')
            .fontWeight(FontWeight.Medium)

          Text(`Strokes: ${this.strokeCount}`)
            .fontSize(10)
            .fontColor('#000000')
            .fontWeight(FontWeight.Medium)

          Text(`Distance: ${this.distanceMeters.toFixed(1)} m`)
            .fontSize(10)
            .fontColor('#000000')
            .fontWeight(FontWeight.Medium)

          Text(`Speed: ${this.speed.toFixed(2)} m/s`)
            .fontSize(10)
            .fontColor('#000000')
            .fontWeight(FontWeight.Medium)

          Row() {
            Image($r('app.media.reset'))
              .width(14)
              .height(14)
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .onClick(() => {
            this.reset();
          })

        }
        .width('90%')
        .padding(6)
        .backgroundColor('#f5f5f5')
        .borderRadius(12)
        .margin({ top: 10, bottom: 10 })

        Button(this.isRunning ? 'Stop' : 'Start')
          .width('60%')
          .height(20)
          .fontSize(10)
          .backgroundColor(this.isRunning ? '#FF3B30' : '#007AFF')
          .onClick(() => {
            if (this.isRunning) {
              this.stop();
            } else {
              this.start();
            }
          })

        Button('Save')
          .width('60%')
          .height(20)
          .fontSize(10)
          .backgroundColor('#34C759')
          .fontColor(Color.White)
          .enabled(!this.isRunning)
          .opacity(this.isRunning ? 0.5 : 1)
          .onClick(() => {
            this.saveWorkout();
          })

        Button('Show History')
          .width('60%')
          .height(20)
          .fontSize(10)
          .backgroundColor('#8E8E93')
          .fontColor(Color.White)
          .enabled(!this.isRunning)
          .opacity(this.isRunning ? 0.5 : 1)
          .onClick(() => {
            this.navPathStack.pushPath({ name: 'HistoryPage' })
          })
      }
      .width('100%')
      .height('100%')
      .padding(10)
    }
    .onBackPressed(() => {
      this.navPathStack.disableAnimation(true)
      this.navPathStack.replacePathByName('Index', false)
      return true
    })
    .hideTitleBar(true)

  }
}

@Builder
export function IndexPageBuilder() {
  Index();
}