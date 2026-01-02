import { relationalStore } from '@kit.ArkData';

export class SwimRecord {
  id?: number;
  date: string;
  strokes: number;
  distance: number;
  duration: number;
  timestamp: number;

  constructor(date: string, strokes: number, distance: number, duration: number, id?: number) {
    this.id = id;
    this.date = date;
    this.strokes = strokes;
    this.distance = distance;
    this.duration = duration;
    this.timestamp = Date.now();
  }
}

export const SWIM_TABLE_NAME = 'swim_records';
export const CREATE_SWIM_TABLE = `
  CREATE TABLE IF NOT EXISTS ${SWIM_TABLE_NAME} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    strokes INTEGER NOT NULL,
    distance INTEGER NOT NULL,
    duration INTEGER NOT NULL,
    timestamp INTEGER NOT NULL
  )
`;