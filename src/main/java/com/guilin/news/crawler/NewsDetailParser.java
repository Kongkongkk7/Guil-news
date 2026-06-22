package com.guilin.news.crawler;

import com.guilin.news.model.NewsDetail;
import com.guilin.news.util.UrlUtils;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

/**
 * 新闻详情解析器：正文提取、图片绝对化、首图提取。
 *
 * <p>解析逻辑与重构前 {@code NewsService.fetchNewsDetail}/{@code fetchFirstImage}
 * 一致，仅将"抓取"与"解析"职责分离——本类只负责解析已抓取的 {@link Document}。</p>
 */
public class NewsDetailParser {

    /** 官网正文容器的候选选择器（按优先级）。 */
    private static final String CONTENT_SELECTOR =
            ".v_news_content, .article-content, .news-content, #vsb_content, .cont, .c_txt";

    /** 解析详情页，正文中图片补全为绝对地址，并取首图作为缩略图。 */
    public NewsDetail parseDetail(Document doc, String url) {
        NewsDetail detail = new NewsDetail();
        detail.setUrl(url);

        Element titleEl = doc.selectFirst("h1, h2, .article-title, .news-title, .content_title h1");
        if (titleEl != null) {
            detail.setTitle(titleEl.text().trim());
        }

        Element contentEl = doc.select(CONTENT_SELECTOR).first();
        if (contentEl != null) {
            contentEl.select("script, style, iframe").remove();

            for (Element img : contentEl.select("img")) {
                String src = img.attr("src");
                String abs = UrlUtils.absolutizeImage(src);
                if (abs != null && !abs.equals(src)) {
                    img.attr("src", abs);
                }
            }

            detail.setContent(contentEl.html());

            Element firstImg = contentEl.selectFirst("img");
            if (firstImg != null) {
                detail.setThumbnail(firstImg.attr("src"));
            }
        } else {
            Element body = doc.selectFirst("body");
            if (body != null) {
                body.select("script, style, nav, header, footer, .header, .footer, .nav").remove();
                detail.setContent(body.html());
            }
        }

        return detail;
    }

    /**
     * 从详情页文档中提取首图作为列表缩略图。
     *
     * <p>优先取正文容器内首图；否则退而取 body 内首图，但排除 logo/icon/banner。
     * 找不到返回 {@code null}。</p>
     */
    public String extractFirstImage(Document doc) {
        Element contentEl = doc.select(CONTENT_SELECTOR).first();
        if (contentEl != null) {
            Element img = contentEl.selectFirst("img");
            if (img != null) {
                String src = img.attr("src");
                if (src != null && !src.isEmpty()) {
                    return UrlUtils.absolutizeImage(src);
                }
            }
        }

        Element bodyImg = doc.selectFirst("body img[src]");
        if (bodyImg != null) {
            String src = bodyImg.attr("src");
            if (src != null && !src.isEmpty()) {
                String abs = UrlUtils.absolutizeImage(src);
                if (abs != null
                        && !abs.contains("logo") && !abs.contains("icon") && !abs.contains("banner")) {
                    return abs;
                }
            }
        }
        return null;
    }
}
