import { textToSpeech } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';

export type TtsPlaybackState = 'idle' | 'playing' | 'paused' | 'error';

export interface TtsStateSnapshot {
  state: TtsPlaybackState;
  currentIndex: number;
  totalChunks: number;
  errorMessage: string;
}

/**
 * 纯函数集合：TTS 文本清洗、分段、合规请求 ID 构造及错误提示映射
 */
export class TtsReaderHelper {
  /** 纯函数：清理待朗读文本中的 HTML 标签、URL 与多余空白 */
  public static cleanTtsText(raw: string): string {
    if (!raw || raw.trim() === '') {
      return '';
    }
    return raw
      .replace(/<script[\s\S]*?<\/script>/gi, ' ')
      .replace(/<style[\s\S]*?<\/style>/gi, ' ')
      .replace(/<br\s*\/?>/gi, '\n')
      .replace(/<\/(p|div|li|tr|h[1-6])>/gi, '\n')
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;/gi, ' ')
      .replace(/&amp;/gi, '&')
      .replace(/&lt;/gi, '<')
      .replace(/&gt;/gi, '>')
      .replace(/&quot;/gi, '"')
      .replace(/&#39;|&apos;/gi, "'")
      .replace(/https?:\/\/\S+/gi, ' ')
      .replace(/\r\n/g, '\n')
      .replace(/\r/g, '\n')
      .replace(/[ \t\u00A0]+/g, ' ')
      .replace(/\n{2,}/g, '\n')
      .trim();
  }

  /** 纯函数：按句末标点将朗读文本切分为长度不超过 maxChunkLen 的片段 */
  public static splitSpeechChunks(rawText: string, maxChunkLen: number = 400): string[] {
    const cleaned: string = TtsReaderHelper.cleanTtsText(rawText);
    if (cleaned === '') {
      return [];
    }
    const safeMax: number = Number.isFinite(maxChunkLen) && maxChunkLen >= 20
      ? Math.floor(maxChunkLen)
      : 400;
    if (cleaned.length <= safeMax) {
      return [cleaned];
    }

    const sentences: string[] = [];
    let start: number = 0;
    for (let i = 0; i < cleaned.length; i++) {
      const ch: string = cleaned.charAt(i);
      if (ch === '。' || ch === '！' || ch === '？' || ch === '；' || ch === '\n') {
        const seg: string = cleaned.substring(start, i + 1).trim();
        if (seg !== '') {
          sentences.push(seg);
        }
        start = i + 1;
      }
    }
    if (start < cleaned.length) {
      const tail: string = cleaned.substring(start).trim();
      if (tail !== '') {
        sentences.push(tail);
      }
    }

    const chunks: string[] = [];
    let current: string = '';
    for (const sentence of sentences) {
      if (sentence.length > safeMax) {
        if (current !== '') {
          chunks.push(current);
          current = '';
        }
        for (let offset = 0; offset < sentence.length; offset += safeMax) {
          const piece: string = sentence.substring(offset, offset + safeMax).trim();
          if (piece !== '') {
            chunks.push(piece);
          }
        }
        continue;
      }
      const candidate: string = current === '' ? sentence : `${current} ${sentence}`;
      if (candidate.length <= safeMax) {
        current = candidate;
      } else {
        if (current !== '') {
          chunks.push(current);
        }
        current = sentence;
      }
    }
    if (current !== '') {
      chunks.push(current);
    }
    return chunks;
  }

  /** 纯函数：构造仅含字母数字的合规 SpeakParams.requestId */
  public static buildRequestId(seq: number): string {
    const safeSeq: number = Number.isFinite(seq) && seq >= 1 ? Math.floor(seq) : 1;
    return 'sdmuTts' + String(safeSeq);
  }

  /** 纯函数：映射 CoreSpeechKit 错误码为可读提示 */
  public static formatTtsError(code: number): string {
    if (code === 401) {
      return '语音朗读参数无效';
    }
    if (code === 1002300001) {
      return '朗读文本长度超出限制或为空';
    }
    if (code === 1002300002) {
      return '当前设备不支持中文语音朗读';
    }
    if (code === 1002300003) {
      return '当前设备暂不支持该发音人音色';
    }
    if (code === 1002300005) {
      return '语音合成引擎初始化失败，当前设备可能不支持';
    }
    return '当前设备暂不支持语音朗读';
  }
}

/**
 * 纯状态机：管理分段语音朗读队列、播放/暂停/恢复/停止及完成推进（仅在 completeType === 1 时切下一段）
 */
export class TtsSessionMachine {
  public state: TtsPlaybackState = 'idle';
  public chunks: string[] = [];
  public currentIndex: number = 0;
  public lastError: string = '';
  public requestSeq: number = 0;

  public prepare(rawText: string, maxChunkLen: number = 400): string[] {
    this.chunks = TtsReaderHelper.splitSpeechChunks(rawText, maxChunkLen);
    this.currentIndex = 0;
    this.lastError = '';
    this.state = 'idle';
    return this.chunks;
  }

  public markPlaying(): string {
    if (this.chunks.length === 0 || this.currentIndex < 0 || this.currentIndex >= this.chunks.length) {
      this.state = 'idle';
      return '';
    }
    this.state = 'playing';
    this.lastError = '';
    this.requestSeq += 1;
    return this.chunks[this.currentIndex];
  }

  public pause(): void {
    if (this.state === 'playing') {
      this.state = 'paused';
    }
  }

  public resume(): string {
    if (this.state !== 'paused' || this.chunks.length === 0 || this.currentIndex >= this.chunks.length) {
      return '';
    }
    this.state = 'playing';
    this.lastError = '';
    this.requestSeq += 1;
    return this.chunks[this.currentIndex];
  }

  /**
   * 处理合成/播放完成回调：
   * - completeType === 0（仅合成结束）不推进段落，返回 null
   * - completeType === 1（播放结束）推进至下一段或回归 idle
   */
  public handleComplete(completeType: number): string | null {
    if (completeType !== 1 || this.state !== 'playing') {
      return null;
    }
    this.currentIndex += 1;
    if (this.currentIndex < this.chunks.length) {
      this.requestSeq += 1;
      return this.chunks[this.currentIndex];
    }
    this.state = 'idle';
    this.currentIndex = 0;
    return null;
  }

  public stop(): void {
    this.state = 'idle';
    this.currentIndex = 0;
    this.lastError = '';
  }

  public fail(msg: string): void {
    this.state = 'error';
    this.lastError = (msg || '').trim() !== '' ? msg : '当前设备暂不支持语音朗读';
  }

  public getSnapshot(): TtsStateSnapshot {
    return {
      state: this.state,
      currentIndex: this.currentIndex,
      totalChunks: this.chunks.length,
      errorMessage: this.lastError
    };
  }
}

/**
 * 页面级前台 TTS 朗读控制器（仅前台离线模式，零额外权限，页面离开/销毁自动释放引擎）
 */
export class TtsReaderController {
  private engine: textToSpeech.TextToSpeechEngine | null = null;
  private machine: TtsSessionMachine = new TtsSessionMachine();
  private activeRequestId: string = '';
  private disposed: boolean = false;
  private onStateChange: ((snapshot: TtsStateSnapshot) => void) | null = null;

  constructor(onStateChange?: (snapshot: TtsStateSnapshot) => void) {
    if (onStateChange) {
      this.onStateChange = onStateChange;
    }
  }

  public setOnStateChange(cb: ((snapshot: TtsStateSnapshot) => void) | null): void {
    this.onStateChange = cb;
  }

  public getSnapshot(): TtsStateSnapshot {
    return this.machine.getSnapshot();
  }

  private notify(): void {
    if (this.onStateChange !== null) {
      try {
        this.onStateChange(this.machine.getSnapshot());
      } catch {
        // 忽略 UI 回调异常
      }
    }
  }

  private async ensureEngine(): Promise<textToSpeech.TextToSpeechEngine | null> {
    if (this.engine !== null) {
      return this.engine;
    }
    try {
      const initParams: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        person: 13,
        online: 1,
        extraParams: {
          'style': 'interaction-broadcast',
          'locate': 'CN',
          'name': 'SdmuTtsReader'
        }
      };
      const created: textToSpeech.TextToSpeechEngine = await textToSpeech.createEngine(initParams);
      if (this.disposed) {
        try {
          created.shutdown();
        } catch {
          // 忽略销毁异常
        }
        return null;
      }
      const listener: textToSpeech.SpeakListener = {
        onStart: (_requestId: string, _response: textToSpeech.StartResponse): void => {
          // 保持当前播放状态
        },
        onComplete: (requestId: string, response: textToSpeech.CompleteResponse): void => {
          if (this.disposed || requestId !== this.activeRequestId) {
            return;
          }
          const nextChunk: string | null = this.machine.handleComplete(response.type);
          if (nextChunk !== null && this.engine !== null) {
            this.speakChunk(this.engine, nextChunk);
          }
          this.notify();
        },
        onStop: (requestId: string, _response: textToSpeech.StopResponse): void => {
          if (this.disposed || requestId !== this.activeRequestId) {
            return;
          }
          if (this.machine.state === 'playing') {
            this.machine.stop();
            this.notify();
          }
        },
        onError: (requestId: string, errorCode: number, _errorMessage: string): void => {
          if (this.disposed || (this.activeRequestId !== '' && requestId !== this.activeRequestId)) {
            return;
          }
          this.activeRequestId = '';
          this.machine.fail(TtsReaderHelper.formatTtsError(errorCode));
          this.notify();
        }
      };
      created.setListener(listener);
      this.engine = created;
      return created;
    } catch (err) {
      const be = err as BusinessError;
      this.machine.fail(TtsReaderHelper.formatTtsError(be.code ?? -1));
      this.notify();
      return null;
    }
  }

  private speakChunk(engine: textToSpeech.TextToSpeechEngine, chunk: string): void {
    const reqId: string = TtsReaderHelper.buildRequestId(this.machine.requestSeq);
    this.activeRequestId = reqId;
    try {
      const speakParams: textToSpeech.SpeakParams = {
        requestId: reqId,
        extraParams: {
          'speed': 1,
          'volume': 1,
          'pitch': 1,
          'languageContext': 'zh-CN',
          'audioType': 'pcm'
        }
      };
      engine.speak(chunk, speakParams);
    } catch (err) {
      const be = err as BusinessError;
      this.activeRequestId = '';
      this.machine.fail(TtsReaderHelper.formatTtsError(be.code ?? -1));
      this.notify();
    }
  }

  /** 开始朗读指定文本 */
  public async speak(rawText: string): Promise<boolean> {
    this.disposed = false;
    this.activeRequestId = '';
    if (this.engine !== null) {
      try {
        this.engine.stop();
      } catch {
        // 忽略停止旧任务异常
      }
    }
    const chunks: string[] = this.machine.prepare(rawText);
    if (chunks.length === 0) {
      this.machine.fail('暂无可朗读内容');
      this.notify();
      return false;
    }
    const engine: textToSpeech.TextToSpeechEngine | null = await this.ensureEngine();
    if (engine === null || this.disposed) {
      return false;
    }
    const firstChunk: string = this.machine.markPlaying();
    if (firstChunk === '') {
      this.notify();
      return false;
    }
    this.speakChunk(engine, firstChunk);
    this.notify();
    return this.machine.getSnapshot().state === 'playing';
  }

  /** 暂停朗读（保留当前段落进度） */
  public pause(): void {
    if (this.machine.state !== 'playing') {
      return;
    }
    this.activeRequestId = '';
    this.machine.pause();
    if (this.engine !== null) {
      try {
        this.engine.stop();
      } catch {
        // 忽略停止异常
      }
    }
    this.notify();
  }

  /** 从暂停段落继续朗读 */
  public async resume(): Promise<boolean> {
    if (this.machine.state !== 'paused') {
      return false;
    }
    const engine: textToSpeech.TextToSpeechEngine | null = await this.ensureEngine();
    if (engine === null || this.disposed) {
      return false;
    }
    const chunk: string = this.machine.resume();
    if (chunk === '') {
      this.notify();
      return false;
    }
    this.speakChunk(engine, chunk);
    this.notify();
    return this.machine.getSnapshot().state === 'playing';
  }

  /** 停止朗读并重置到初始段 */
  public stop(): void {
    this.activeRequestId = '';
    this.machine.stop();
    if (this.engine !== null) {
      try {
        this.engine.stop();
      } catch {
        // 忽略停止异常
      }
    }
    this.notify();
  }

  /** 幂等释放语音引擎（应在 onPageHide 与 aboutToDisappear 中调用） */
  public shutdown(): void {
    this.disposed = true;
    this.activeRequestId = '';
    this.machine.stop();
    if (this.engine !== null) {
      try {
        this.engine.stop();
      } catch {
        // 忽略停止异常
      }
      try {
        this.engine.shutdown();
      } catch {
        // 忽略释放异常
      }
      this.engine = null;
    }
    this.notify();
  }
}
