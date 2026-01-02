import { ConstantUI } from '../util/ConstantUI';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { SwimRecord } from '../model/SwimRecord';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const TAG = 'HistoryPage';
const DOMAIN = 0x0000;

@Component
export struct HistoryPage {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @State swimRecords: SwimRecord[] = [];
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  async aboutToAppear() {
    hilog.info(DOMAIN, TAG, 'aboutToAppear called');
    console.info('[HistoryPage] aboutToAppear started');

    try {
      hilog.info(DOMAIN, TAG, 'Initializing database...');
      await this.dbHelper.initDatabase(this.context);
      hilog.info(DOMAIN, TAG, 'Database initialized');

      hilog.info(DOMAIN, TAG, 'Loading records...');
      await this.loadRecords();
      hilog.info(DOMAIN, TAG, 'Records loaded: %{public}d', this.swimRecords.length);
      console.info('[HistoryPage] Records loaded:', this.swimRecords.length);

      if (this.swimRecords.length === 0) {
        hilog.info(DOMAIN, TAG, 'No records found, inserting mock data...');
        console.info('[HistoryPage] No records found, inserting mock data');
        await this.insertMockData();
        await this.loadRecords();
        hilog.info(DOMAIN, TAG, 'Mock data inserted. Total records: %{public}d', this.swimRecords.length);
        console.info('[HistoryPage] Mock data inserted. Total records:', this.swimRecords.length);
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Error in aboutToAppear: %{public}s', JSON.stringify(err));
      console.error('[HistoryPage] Error in aboutToAppear:', JSON.stringify(err));
    }
  }

  async loadRecords() {
    hilog.info(DOMAIN, TAG, 'loadRecords called');
    try {
      this.swimRecords = await this.dbHelper.getAllRecords();
      hilog.info(DOMAIN, TAG, 'Records loaded successfully');
      console.info('[HistoryPage] Records loaded successfully:', this.swimRecords);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Error loading records: %{public}s', JSON.stringify(err));
      console.error('[HistoryPage] Error loading records:', JSON.stringify(err));
    }
  }

  async insertMockData() {
    hilog.info(DOMAIN, TAG, 'insertMockData called');
    const mockRecords = [
      new SwimRecord('December 18, 2025', 450, 500, 25),
      new SwimRecord('December 17, 2025', 380, 425, 22),
      new SwimRecord('December 15, 2025', 520, 575, 28),
      new SwimRecord('December 14, 2025', 410, 460, 24),
      new SwimRecord('December 12, 2025', 490, 540, 26),
      new SwimRecord('December 10, 2025', 360, 400, 21),
      new SwimRecord('December 8, 2025', 470, 515, 25)
    ];

    console.info('[HistoryPage] Inserting', mockRecords.length, 'mock records');

    for (let i = 0; i < mockRecords.length; i++) {
      hilog.info(DOMAIN, TAG, 'Inserting record %{public}d/%{public}d', i + 1, mockRecords.length);
      const rowId = await this.dbHelper.insertRecord(mockRecords[i]);
      hilog.info(DOMAIN, TAG, 'Record inserted with ID: %{public}d', rowId);
    }

    hilog.info(DOMAIN, TAG, 'All mock data inserted');
    console.info('[HistoryPage] All mock data inserted');
  }

  async deleteRecord(id: number | undefined) {
    hilog.info(DOMAIN, TAG, 'deleteRecord called with id: %{public}d', id);
    console.info('[HistoryPage] Deleting record with id:', id);

    if (id === undefined) {
      hilog.error(DOMAIN, TAG, 'Invalid ID: undefined');
      console.error('[HistoryPage] Invalid ID: undefined');
      return;
    }

    try {
      const success = await this.dbHelper.deleteRecord(id);
      hilog.info(DOMAIN, TAG, 'Delete result: %{public}s', success ? 'success' : 'failed');
      console.info('[HistoryPage] Delete result:', success);

      if (success) {
        await this.loadRecords();
        hilog.info(DOMAIN, TAG, 'Records reloaded after deletion');
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Error deleting record: %{public}s', JSON.stringify(err));
      console.error('[HistoryPage] Error deleting record:', JSON.stringify(err));
    }
  }

  build() {
    NavDestination() {
      Column() {
        Text('Swimming History')
          .fontSize(ConstantUI.FONT_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a1a')
          .margin({ top: ConstantUI.MARGIN_MEDIUM, bottom: ConstantUI.PADDING_EDGE })

        Text(`Records: ${this.swimRecords.length}`)
          .fontSize(ConstantUI.VERSION_FONT)
          .fontColor('#999999')
          .margin({ bottom: ConstantUI.MARGIN_SMALL })

        if (this.swimRecords.length === 0) {
          Column() {
            Text('No swimming records yet')
              .fontSize(ConstantUI.TEXT)
              .fontColor('#999999')
              .margin({ top: ConstantUI.MARGIN_LARGE })
            Text('Loading...')
              .fontSize(ConstantUI.VERSION_FONT)
              .fontColor('#cccccc')
              .margin({ top: ConstantUI.MARGIN_SMALL })
          }
          .width(ConstantUI.FULL_WIDTH)
          .layoutWeight(1)
          .justifyContent(FlexAlign.Start)
        } else {
          List({ space: ConstantUI.MARGIN_SMALL }) {
            ForEach(this.swimRecords, (record: SwimRecord) => {
              ListItem() {
                this.SwimRecordItem(record)
              }
              .swipeAction({ end: this.deleteButton(record.id) })
            }, (record: SwimRecord) => record.id?.toString())
          }
          .width(ConstantUI.FULL_WIDTH)
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width(ConstantUI.FULL_WIDTH)
      .height(ConstantUI.FULL_HEIGHT)
      .padding({ left: ConstantUI.PADDING_EDGE, right: ConstantUI.PADDING_EDGE })
    }
    .width(ConstantUI.FULL_WIDTH)
    .height(ConstantUI.FULL_HEIGHT)
    .backgroundColor('#f5f5f5')
  }

  @Builder
  SwimRecordItem(record: SwimRecord) {
    Column() {
      Text(`ID: ${record.id}`)
        .fontSize(ConstantUI.FONT_SMALL_EXTRA)
        .fontColor('#cccccc')
        .width(ConstantUI.FULL_WIDTH)
        .margin({ bottom: ConstantUI.MARGIN_TINY })

      Row() {
        Image($rawfile('icons/calendar.svg'))
          .width(ConstantUI.ICON_SMALL)
          .height(ConstantUI.ICON_SMALL)
        Text(record.date)
          .fontSize(ConstantUI.FONT_SMALL_MEDIUM)
          .fontColor('#666666')
          .margin({ left: ConstantUI.MARGIN_MINI })
      }
      .width(ConstantUI.FULL_WIDTH)
      .margin({ bottom: ConstantUI.MARGIN_MEDIUM_SMALL })

      Row() {
        Column() {
          Image($rawfile('icons/swimming.svg'))
            .width(ConstantUI.ICON_MEDIUM)
            .height(ConstantUI.ICON_MEDIUM)
          Text(record.strokes.toString())
            .fontSize(ConstantUI.BUTTON_FONT)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0A59F7')
            .margin({ top: ConstantUI.MARGIN_TINY })
          Text('Strokes')
            .fontSize(ConstantUI.FONT_BODY)
            .fontColor('#999999')
            .margin({ top: ConstantUI.MARGIN_EXTRA_SMALL })
        }
        .layoutWeight(1)

        Column() {
          Image($rawfile('icons/distance.svg'))
            .width(ConstantUI.ICON_MEDIUM)
            .height(ConstantUI.ICON_MEDIUM)
          Text(record.distance.toString())
            .fontSize(ConstantUI.BUTTON_FONT)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00C853')
            .margin({ top: ConstantUI.MARGIN_TINY })
          Text('Meters')
            .fontSize(ConstantUI.FONT_BODY)
            .fontColor('#999999')
            .margin({ top: ConstantUI.MARGIN_EXTRA_SMALL })
        }
        .layoutWeight(1)

        Column() {
          Image($rawfile('icons/time.svg'))
            .width(ConstantUI.ICON_MEDIUM)
            .height(ConstantUI.ICON_MEDIUM)
          Text(record.duration.toString())
            .fontSize(ConstantUI.BUTTON_FONT)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6D00')
            .margin({ top: ConstantUI.MARGIN_TINY })
          Text('Minutes')
            .fontSize(ConstantUI.FONT_BODY)
            .fontColor('#999999')
            .margin({ top: ConstantUI.MARGIN_EXTRA_SMALL })
        }
        .layoutWeight(1)
      }
      .width(ConstantUI.FULL_WIDTH)
    }
    .width(ConstantUI.FULL_WIDTH)
    .padding(ConstantUI.PADDING_LARGE)
    .backgroundColor(Color.White)
    .borderRadius(ConstantUI.ITEM_RADIUS)
    .shadow({
      radius: ConstantUI.SHADOW_RADIUS,
      color: '#10000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  deleteButton(id: number | undefined) {
    Button() {
      Image($rawfile('icons/delete.svg'))
        .width(ConstantUI.ICON_LARGE)
        .height(ConstantUI.ICON_LARGE)
    }
    .width(ConstantUI.DELETE_BUTTON_WIDTH)
    .height(ConstantUI.FULL_HEIGHT)
    .type(ButtonType.Normal)
    .backgroundColor('#FF3B30')
    .borderRadius(ConstantUI.ITEM_RADIUS)
    .onClick(() => {
      console.info('[HistoryPage] Delete button clicked for id:', id);
      this.deleteRecord(id);
    })
  }
}

@Builder
export function HistoryPageBuilder() {
  HistoryPage();
}