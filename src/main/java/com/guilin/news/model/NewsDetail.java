package com.guilin.news.model;

/**
 * 新闻详情 DTO。
 *
 * <p>替代重构前的 {@code Map<String, String>}，提供类型安全。字段名与原 Map 的
 * 键保持一致（{@code title/content/url/thumbnail}），因此 Gson 序列化后结构不变，
 * 前端无需改动。</p>
 */
public class NewsDetail {

    private String title;
    private String content;
    private String url;
    private String thumbnail;

    public NewsDetail() {
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getThumbnail() {
        return thumbnail;
    }

    public void setThumbnail(String thumbnail) {
        this.thumbnail = thumbnail;
    }
}
