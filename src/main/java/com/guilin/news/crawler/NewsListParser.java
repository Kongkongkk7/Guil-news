package com.guilin.news.crawler;

import com.guilin.news.config.AppConfig;
import com.guilin.news.model.News;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 新闻列表解析器：三级降级策略适配官网不同分类页面的 HTML 结构。
 *
 * <ol>
 *   <li>标准列表页：{@code li} 中的 {@code a[href*=info/]}</li>
 *   <li>备用链接格式：{@code a[href*=../info/]}</li>
 *   <li>桂院人物页（特殊结构）：{@code a.block[title]}</li>
 * </ol>
 *
 * <p>解析规则、标题/日期清洗与过滤条件与重构前 {@code NewsService.fetchNews} 中
 * 逐字一致，仅迁移位置。</p>
 */
public class NewsListParser {

    private static final Pattern DATE_PREFIX = Pattern.compile("^(\\d{4}年\\d{2}月\\d{2}日)");
    private static final String BASE = AppConfig.BASE_URL;

    /** 解析列表页，返回去重前的新闻列表（缩略图字段留空，由上层并发补全）。 */
    public List<News> parse(Document doc) {
        List<News> newsList = new ArrayList<>();

        // 策略一：标准列表页 li > a[href*=info/]
        Elements newsItems = doc.select("li, .news-item, .list-item");
        for (Element item : newsItems) {
            Element linkEl = item.selectFirst("a[href*=info/]");
            if (linkEl == null) continue;

            String title = linkEl.text().trim();
            String href = linkEl.attr("href");

            if (href.startsWith("../info/")) {
                href = href.replace("../", BASE + "/");
            } else if (href.startsWith("info/")) {
                href = BASE + "/" + href;
            }

            String date = extractDateFromTitle(title);

            // 标题中无日期时，尝试从 span 中提取
            if (date.isEmpty()) {
                Elements spans = item.select("span");
                for (Element span : spans) {
                    String spanText = span.text().trim();
                    if (spanText.matches("\\d{4}[-/]\\d{2}[-/]\\d{2}") || spanText.matches("\\d{4}年.*")) {
                        date = spanText;
                        break;
                    }
                }
            }

            String cleanTitle = title.replaceFirst("^\\d{4}年\\d{2}月\\d{2}日\\s*", "");

            if (isValidEntry(cleanTitle, href)) {
                newsList.add(new News(cleanTitle, href, date, ""));
            }
        }

        // 策略二：备用链接格式 a[href*=../info/]
        if (newsList.isEmpty()) {
            Elements links = doc.select("a[href*=../info/]");
            for (Element link : links) {
                String title = link.text().trim();
                String href = link.attr("href");

                if (href.startsWith("../info/")) {
                    href = href.replace("../", BASE + "/");
                }

                String date = extractDateFromTitle(title);
                String cleanTitle = title.replaceFirst("^\\d{4}年\\d{2}月\\d{2}日\\s*", "");

                if (isValidEntry(cleanTitle, href)) {
                    newsList.add(new News(cleanTitle, href, date, ""));
                }
            }
        }

        // 策略三：桂院人物页 a.block[title]（链接格式不同）
        if (newsList.isEmpty()) {
            Elements blockLinks = doc.select("a.block[title]");
            for (Element link : blockLinks) {
                String title = link.attr("title").trim();
                String href = link.attr("href");

                if (href.isEmpty() || title.isEmpty()) continue;

                if (href.startsWith("../")) {
                    href = href.replace("../", BASE + "/");
                } else if (href.startsWith("/") && !href.startsWith("//")) {
                    href = BASE + href;
                }

                // 从隐藏 div 中提取日期
                String date = "";
                Element hiddenDate = link.selectFirst("div[style*=display:none]");
                if (hiddenDate != null) {
                    date = hiddenDate.text().trim();
                }

                if (title.length() > 4) {
                    newsList.add(new News(title, href, date, ""));
                }
            }
        }

        return newsList;
    }

    /** 标题/链接有效性过滤，规则与重构前一致。 */
    private boolean isValidEntry(String cleanTitle, String href) {
        return !cleanTitle.isEmpty() && !href.isEmpty() && href.contains("info/")
                && !cleanTitle.contains("历任校领导")
                && !cleanTitle.contains("信息公开")
                && cleanTitle.length() > 4;
    }

    /** 从标题中提取 "2026年06月01日" 格式的日期，无则返回空串。 */
    private String extractDateFromTitle(String title) {
        Matcher matcher = DATE_PREFIX.matcher(title);
        return matcher.find() ? matcher.group(1) : "";
    }
}
