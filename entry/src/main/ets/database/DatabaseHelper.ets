import { relationalStore } from '@kit.ArkData';
import { SwimRecord, SWIM_TABLE_NAME, CREATE_SWIM_TABLE } from '../model/SwimRecord';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'DatabaseHelper';
const DOMAIN = 0x0000;

export class DatabaseHelper {
  private rdbStore: relationalStore.RdbStore | null = null;
  private static instance: DatabaseHelper;

  private constructor() {
    hilog.info(DOMAIN, TAG, 'DatabaseHelper constructor called');
  }

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper();
      hilog.info(DOMAIN, TAG, 'DatabaseHelper instance created');
    }
    return DatabaseHelper.instance;
  }

  async initDatabase(context: Context): Promise<void> {
    hilog.info(DOMAIN, TAG, 'initDatabase started');

    const config: relationalStore.StoreConfig = {
      name: 'SwimTrackerDB.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      hilog.info(DOMAIN, TAG, 'Getting RDB store...');
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      hilog.info(DOMAIN, TAG, 'RDB store obtained successfully');

      await this.rdbStore.executeSql(CREATE_SWIM_TABLE);
      hilog.info(DOMAIN, TAG, 'Table created successfully');

      console.info('[DatabaseHelper] Database initialized successfully');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to init database: %{public}s', JSON.stringify(err));
      console.error('[DatabaseHelper] Failed to init database:', JSON.stringify(err));
    }
  }

  async insertRecord(record: SwimRecord): Promise<number> {
    hilog.info(DOMAIN, TAG, 'insertRecord called');

    if (!this.rdbStore) {
      hilog.error(DOMAIN, TAG, 'Database not initialized');
      console.error('[DatabaseHelper] Database not initialized');
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'date': record.date,
      'strokes': record.strokes,
      'distance': record.distance,
      'duration': record.duration,
      'timestamp': record.timestamp
    };

    hilog.info(DOMAIN, TAG, 'Inserting record: %{public}s', JSON.stringify(valueBucket));

    try {
      const rowId = await this.rdbStore.insert(SWIM_TABLE_NAME, valueBucket);
      hilog.info(DOMAIN, TAG, 'Record inserted with ID: %{public}d', rowId);
      console.info('[DatabaseHelper] Record inserted with ID:', rowId);
      return rowId;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to insert record: %{public}s', JSON.stringify(err));
      console.error('[DatabaseHelper] Failed to insert record:', JSON.stringify(err));
      return -1;
    }
  }

  async getAllRecords(): Promise<SwimRecord[]> {
    hilog.info(DOMAIN, TAG, 'getAllRecords called');

    if (!this.rdbStore) {
      hilog.error(DOMAIN, TAG, 'Database not initialized');
      console.error('[DatabaseHelper] Database not initialized');
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(SWIM_TABLE_NAME);
    predicates.orderByDesc('timestamp');

    try {
      hilog.info(DOMAIN, TAG, 'Querying records...');
      const resultSet = await this.rdbStore.query(predicates);
      const records: SwimRecord[] = [];

      hilog.info(DOMAIN, TAG, 'Result set row count: %{public}d', resultSet.rowCount);
      console.info('[DatabaseHelper] Result set row count:', resultSet.rowCount);

      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const date = resultSet.getString(resultSet.getColumnIndex('date'));
        const strokes = resultSet.getLong(resultSet.getColumnIndex('strokes'));
        const distance = resultSet.getLong(resultSet.getColumnIndex('distance'));
        const duration = resultSet.getLong(resultSet.getColumnIndex('duration'));

        hilog.info(DOMAIN, TAG, 'Record: id=%{public}d, date=%{public}s, strokes=%{public}d',
          id, date, strokes);

        const record = new SwimRecord(date, strokes, distance, duration, id);
        records.push(record);
      }

      resultSet.close();
      hilog.info(DOMAIN, TAG, 'Query completed. Total records: %{public}d', records.length);
      console.info('[DatabaseHelper] Query completed. Total records:', records.length);
      return records;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to query records: %{public}s', JSON.stringify(err));
      console.error('[DatabaseHelper] Failed to query records:', JSON.stringify(err));
      return [];
    }
  }

  async deleteRecord(id: number): Promise<boolean> {
    hilog.info(DOMAIN, TAG, 'deleteRecord called with id: %{public}d', id);

    if (!this.rdbStore) {
      hilog.error(DOMAIN, TAG, 'Database not initialized');
      console.error('[DatabaseHelper] Database not initialized');
      return false;
    }

    const predicates = new relationalStore.RdbPredicates(SWIM_TABLE_NAME);
    predicates.equalTo('id', id);

    try {
      const rows = await this.rdbStore.delete(predicates);
      hilog.info(DOMAIN, TAG, 'Deleted rows: %{public}d', rows);
      console.info('[DatabaseHelper] Deleted rows:', rows);
      return rows > 0;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to delete record: %{public}s', JSON.stringify(err));
      console.error('[DatabaseHelper] Failed to delete record:', JSON.stringify(err));
      return false;
    }
  }

  async updateRecord(record: SwimRecord): Promise<boolean> {
    hilog.info(DOMAIN, TAG, 'updateRecord called');

    if (!this.rdbStore || !record.id) {
      hilog.error(DOMAIN, TAG, 'Database not initialized or invalid record');
      console.error('[DatabaseHelper] Database not initialized or invalid record');
      return false;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'date': record.date,
      'strokes': record.strokes,
      'distance': record.distance,
      'duration': record.duration,
      'timestamp': record.timestamp
    };

    const predicates = new relationalStore.RdbPredicates(SWIM_TABLE_NAME);
    predicates.equalTo('id', record.id);

    try {
      const rows = await this.rdbStore.update(valueBucket, predicates);
      hilog.info(DOMAIN, TAG, 'Updated rows: %{public}d', rows);
      console.info('[DatabaseHelper] Updated rows:', rows);
      return rows > 0;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to update record: %{public}s', JSON.stringify(err));
      console.error('[DatabaseHelper] Failed to update record:', JSON.stringify(err));
      return false;
    }
  }

  async clearAllRecords(): Promise<boolean> {
    hilog.info(DOMAIN, TAG, 'clearAllRecords called');

    if (!this.rdbStore) {
      hilog.error(DOMAIN, TAG, 'Database not initialized');
      console.error('[DatabaseHelper] Database not initialized');
      return false;
    }

    try {
      await this.rdbStore.executeSql(`DELETE FROM ${SWIM_TABLE_NAME}`);
      hilog.info(DOMAIN, TAG, 'All records cleared');
      console.info('[DatabaseHelper] All records cleared');
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to clear records: %{public}s', JSON.stringify(err));
      console.error('[DatabaseHelper] Failed to clear records:', JSON.stringify(err));
      return false;
    }
  }
}