/**
 * 农历工具 — 1:1 移植 LunarCalendar（report/mobile_campus/module/b/j/a.java）：
 *   1900 年基准位表 f16165c + 节气/节日双表，b(y,m,d,false) 返回：
 *     命中公历节日表 → "元旦/国庆节/…"；命中农历节日表 → "春节/元宵节/…"；
 *     农历初一 → "X月"；其余 → a(day)（初X/十X/廿X/卅X，10 特判"初十"）。
 *   LoginedLaunchActivity.J2 用结果串判初/十/廿/卅/月后缀决定"今天是X"或时段问候。
 *   依赖常量 PlaybackStateCompat.ACTION_PREPARE_FROM_SEARCH = 65536 = 闰月大小位（源码实值）。
 */
const LUNAR_INFO: number[] = [
  19416, 19168, 42352, 21717, 53856, 55632, 91476, 22176, 39632, 21970,
  19168, 42422, 42192, 53840, 119381, 46400, 54944, 44450, 38320, 84343,
  18800, 42160, 46261, 27216, 27968, 109396, 11104, 38256, 21234, 18800,
  25958, 54432, 59984, 28309, 23248, 11104, 100067, 37600, 116951, 51536,
  54432, 120998, 46416, 22176, 107956, 9680, 37584, 53938, 43344, 46423,
  27808, 46416, 86869, 19872, 42448, 83315, 21200, 43432, 59728, 27296,
  44710, 43856, 19296, 43748, 42352, 21088, 62051, 55632, 23383, 22176,
  38608, 19925, 19152, 42192, 54484, 53840, 54616, 46400, 46496, 103846,
  38320, 18864, 43380, 42160, 45690, 27216, 27968, 44870, 43872, 38256,
  19189, 18800, 25776, 29859, 59984, 27480, 21952, 43872, 38613, 37600,
  51552, 55636, 54432, 55888, 30034, 22176, 43959, 9680, 37584, 51893,
  43344, 46240, 47780, 44368, 21977, 19360, 42416, 86390, 21168, 43312,
  31060, 27296, 44368, 23378, 19296, 42726, 42208, 53856, 60005, 54576,
  23200, 30371, 38608, 19415, 19152, 42192, 118966, 53840, 54560, 56645,
  46496, 22224, 21938, 18864, 42359, 42160, 43600, 111189, 27936, 44448
];
const MONTH_NAMES: string[] = ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '十一', '十二'];
const DAY_PREFIX: string[] = ['初', '十', '廿', '卅'];
/** 公历节日表（源码 e：mmdd 节日名） */
const SOLAR_FESTIVALS: string[] = ['0101 元旦', '0308 妇女节', '0312 植树节', '0501 劳动节',
  '0504 青年节', '0701 建党节', '0801 建军节', '0910 教师节', '1001 国庆节'];
/** 农历节日表（源码 f16166d；"0100 除夕" 按源码匹配规则永不命中，保真保留） */
const LUNAR_FESTIVALS: string[] = ['0101 春节', '0115 元宵节', '0505 端午节', '0815 中秋节',
  '1208 腊八节', '0100 除夕'];
/** 源码 PlaybackStateCompat.ACTION_PREPARE_FROM_SEARCH 实值（闰月大小判断位） */
const LEAP_MONTH_BIT: number = 65536;

/** 源码 a(day)：初X/十X/廿X/卅X（10 → "初十"，>30 → ""） */
function lunarDayName(day: number): string {
  const d: number = day % 10;
  const idx: number = d === 0 ? 9 : d - 1;
  if (day > 30) {
    return '';
  }
  if (day === 10) {
    return '初十';
  }
  return DAY_PREFIX[Math.floor(day / 10)] + MONTH_NAMES[idx];
}

/** 源码 d(year)：闰月月份（info & 0xF） */
function leapMonth(year: number): number {
  return LUNAR_INFO[year - 1900] & 15;
}

/** 源码 c(year)：闰月天数（& 0x10000 → 30/29） */
function leapDays(year: number): number {
  if (leapMonth(year) !== 0) {
    return (LUNAR_INFO[year - 1900] & LEAP_MONTH_BIT) !== 0 ? 30 : 29;
  }
  return 0;
}

/** 源码 e(year, month)：普通月天数（65536>>month 位 → 30/29） */
function monthDays(year: number, month: number): number {
  const bit: number = Math.floor(65536 / Math.pow(2, month));
  return ((bit & LUNAR_INFO[year - 1900]) === 0 ? 29 : 30);
}

/** 源码 h(year)：农历年总天数（348 + 高位 0x8000..0x10 位计数 + 闰月天数） */
function yearDays(year: number): number {
  let sum: number = 348;
  for (let bit: number = 32768; bit > 8; bit = Math.floor(bit / 2)) {
    if ((LUNAR_INFO[year - 1900] & bit) !== 0) {
      sum++;
    }
  }
  return sum + leapDays(year);
}

function pad2(n: number): string {
  return n < 10 ? '0' + n : String(n);
}

export class LunarCalendar {
  private lunarYear: number = 0;
  private lunarMonth: number = 0;
  private lunarDay: number = 0;

  /** 源码 b(y, m, d, z=false)：公历 → 农历串/节日名 */
  lunarString(year: number, month: number, day: number, withFestival: boolean): string {
    const baseUtc: number = Date.UTC(1900, 0, 31);
    const curUtc: number = Date.UTC(year, month - 1, day);
    let offset: number = Math.floor((curUtc - baseUtc) / 86400000);
    let y: number = 1900;
    let daysInYear: number = 0;
    while (y < 10000 && offset > 0) {
      daysInYear = yearDays(y);
      offset -= daysInYear;
      y++;
    }
    if (offset < 0) {
      offset += daysInYear;
      y--;
    }
    this.lunarYear = y;
    const leap: number = leapMonth(y);
    let isLeap: boolean = false;
    let i: number = 1;
    let temp: number = 0;
    while (i < 13 && offset > 0) {
      if (leap <= 0 || i !== leap + 1 || isLeap) {
        temp = monthDays(y, i);
      } else {
        i--;
        isLeap = true;
        temp = leapDays(y);
      }
      offset -= temp;
      if (isLeap && i === leap + 1) {
        isLeap = false;
      }
      i++;
    }
    if (offset === 0 && leap > 0 && i === leap + 1) {
      if (isLeap) {
        isLeap = false;
      } else {
        isLeap = true;
        i--;
      }
    }
    if (offset < 0) {
      offset += temp;
      i--;
    }
    this.lunarMonth = i;
    this.lunarDay = offset + 1;
    if (!withFestival) {
      // 公历节日表（mmdd 匹配）
      for (const entry of SOLAR_FESTIVALS) {
        const parts: string[] = entry.split(' ');
        if (parts[0].trim() === pad2(month) + pad2(day)) {
          return parts[1];
        }
      }
      // 农历节日表（农历月/日 mmdd 匹配；"0100 除夕" 按源码规则永不命中）
      for (const entry of LUNAR_FESTIVALS) {
        const parts: string[] = entry.split(' ');
        if (parts[0].trim() === pad2(this.lunarMonth) + pad2(this.lunarDay)) {
          return parts[1];
        }
      }
    }
    if (this.lunarDay !== 1) {
      return lunarDayName(this.lunarDay);
    }
    return MONTH_NAMES[this.lunarMonth - 1] + '月';
  }
}
