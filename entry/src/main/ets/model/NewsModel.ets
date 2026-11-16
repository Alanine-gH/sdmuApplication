export class NewsItem {
  id: string;
  title: string;
  summary: string;
  content: string;
  source: string;
  publishTime: string;
  url: string;
  imageUrl: string;
  category: string;

  constructor(id: string, title: string, summary: string, content: string, source: string,
    publishTime: string, url: string, imageUrl: string, category: string) {
    this.id = id;
    this.title = title;
    this.summary = summary;
    this.content = content;
    this.source = source;
    this.publishTime = publishTime;
    this.url = url;
    this.imageUrl = imageUrl;
    this.category = category;
  }
}
