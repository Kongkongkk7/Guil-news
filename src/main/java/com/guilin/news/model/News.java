package com.guilin.news.model;

public class News {
    private String title;
    private String link;
    private String date;
    private String thumbnail;

    public News() {}

    public News(String title, String link, String date) {
        this.title = title;
        this.link = link;
        this.date = date;
    }

    public News(String title, String link, String date, String thumbnail) {
        this.title = title;
        this.link = link;
        this.date = date;
        this.thumbnail = thumbnail;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getLink() {
        return link;
    }

    public void setLink(String link) {
        this.link = link;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public String getThumbnail() {
        return thumbnail;
    }

    public void setThumbnail(String thumbnail) {
        this.thumbnail = thumbnail;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        News news = (News) o;
        return link != null ? link.equals(news.link) : news.link == null;
    }

    @Override
    public int hashCode() {
        return link != null ? link.hashCode() : 0;
    }

    @Override
    public String toString() {
        return "News{" +
                "title='" + title + '\'' +
                ", link='" + link + '\'' +
                ", date='" + date + '\'' +
                ", thumbnail='" + thumbnail + '\'' +
                '}';
    }
}
