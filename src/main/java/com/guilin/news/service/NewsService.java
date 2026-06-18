package com.guilin.news.service;

import com.guilin.news.model.News;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import java.io.IOException;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantReadWriteLock;

public class NewsService {

    private static final Map<String, String> CATEGORY_MAP = new HashMap<>();

    // 缓存：分类 -> (时间戳, 新闻列表)
    private static final Map<String, CacheEntry> CACHE = new HashMap<>();
    private static final ReentrantReadWriteLock CACHE_LOCK = new ReentrantReadWriteLock();
    private static final long CACHE_TTL_MS = 5 * 60 * 1000; // 5分钟缓存

    static class CacheEntry {
        final long timestamp;
        final List<News> newsList;
        CacheEntry(List<News> newsList) {
            this.timestamp = System.currentTimeMillis();
            this.newsList = newsList;
        }
        boolean isExpired() {
            return System.currentTimeMillis() - timestamp > CACHE_TTL_MS;
        }
    }

    static {
        CATEGORY_MAP.put("xxxw", "https://www.glc.edu.cn/xwzx/xxxw.htm");
        CATEGORY_MAP.put("xsdt", "https://www.glc.edu.cn/xwzx/xsdt.htm");
        CATEGORY_MAP.put("xykx", "https://www.glc.edu.cn/xwzx/xykx.htm");
        CATEGORY_MAP.put("gyrw", "https://www.glc.edu.cn/xwzx/gyrw.htm");
        CATEGORY_MAP.put("mtgy", "https://www.glc.edu.cn/xwgk2/mtgy.htm");
    }

    public static String getCategoryName(String category) {
        switch (category) {
            case "xxxw":
                return "桂院要闻";
            case "xsdt":
                return "学术动态";
            case "xykx":
                return "校园快讯";
            case "gyrw":
                return "桂院人物";
            case "mtgy":
                return "媒体关注";
            default:
                return "未知分类";
        }
    }

    // glc.edu.cn 页面为 UTF-8 编码，但 Jsoup 自动检测可能失败，强制用 UTF-8 解码
    private static final Charset GLC_CHARSET = Charset.forName("UTF-8");

    private Document fetchDocument(String url) throws IOException {
        Connection.Response response = Jsoup.connect(url)
                .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                .timeout(10000)
                .execute();
        byte[] bytes = response.bodyAsBytes();
        return Jsoup.parse(new String(bytes, GLC_CHARSET), url);
    }

    public List<News> fetchNews(String category) throws IOException {
        String url = CATEGORY_MAP.get(category);
        if (url == null) {
            throw new IllegalArgumentException("未知的新闻分类: " + category);
        }

        // 检查缓存
        CACHE_LOCK.readLock().lock();
        try {
            CacheEntry entry = CACHE.get(category);
            if (entry != null && !entry.isExpired()) {
                return new ArrayList<>(entry.newsList);
            }
        } finally {
            CACHE_LOCK.readLock().unlock();
        }

        // 缓存过期或不存在，重新抓取
        CACHE_LOCK.writeLock().lock();
        try {
            // 双重检查，防止并发重复抓取
            CacheEntry entry = CACHE.get(category);
            if (entry != null && !entry.isExpired()) {
                return new ArrayList<>(entry.newsList);
            }

            List<News> newsList = new ArrayList<>();

            Document doc = fetchDocument(url);

        Elements newsItems = doc.select("li, .news-item, .list-item");

        for (Element item : newsItems) {
            Element linkEl = item.selectFirst("a[href*=info/]");
            if (linkEl == null) continue;

            String title = linkEl.text().trim();
            String href = linkEl.attr("href");

            if (href.startsWith("../info/")) {
                href = href.replace("../", "https://www.glc.edu.cn/");
            } else if (href.startsWith("info/")) {
                href = "https://www.glc.edu.cn/" + href;
            }

            // 从标题中提取日期（格式如 "2026年06月01日 新闻标题"）
            String date = extractDateFromTitle(title);

            // 如果标题中没有日期，尝试从 span 中提取
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

            // 清理标题中的日期前缀
            String cleanTitle = title.replaceFirst("^\\d{4}年\\d{2}月\\d{2}日\\s*", "");

            if (!cleanTitle.isEmpty() && !href.isEmpty() && href.contains("info/")
                    && !cleanTitle.contains("历任校领导")
                    && !cleanTitle.contains("信息公开")
                    && cleanTitle.length() > 4) {
                News news = new News(cleanTitle, href, date, "");
                newsList.add(news);
            }
        }

        if (newsList.isEmpty()) {
            Elements links = doc.select("a[href*=../info/]");
            for (Element link : links) {
                String title = link.text().trim();
                String href = link.attr("href");

                if (href.startsWith("../info/")) {
                    href = href.replace("../", "https://www.glc.edu.cn/");
                }

                // 从标题中提取日期
                String date = extractDateFromTitle(title);

                // 清理标题中的日期前缀
                String cleanTitle = title.replaceFirst("^\\d{4}年\\d{2}月\\d{2}日\\s*", "");

                if (!cleanTitle.isEmpty() && !href.isEmpty() && href.contains("info/")
                        && !cleanTitle.contains("历任校领导")
                        && !cleanTitle.contains("信息公开")
                        && cleanTitle.length() > 4) {
                    News news = new News(cleanTitle, href, date, "");
                    newsList.add(news);
                }
            }
        }

        // 桂院人物页面解析（链接格式不同，使用 a.block 选择器）
        if (newsList.isEmpty()) {
            Elements blockLinks = doc.select("a.block[title]");
            for (Element link : blockLinks) {
                String title = link.attr("title").trim();
                String href = link.attr("href");

                if (href.isEmpty() || title.isEmpty()) continue;

                // 处理相对路径
                if (href.startsWith("../")) {
                    href = href.replace("../", "https://www.glc.edu.cn/");
                } else if (href.startsWith("/") && !href.startsWith("//")) {
                    href = "https://www.glc.edu.cn" + href;
                }

                // 从隐藏的 div 中提取日期
                String date = "";
                Element hiddenDate = link.selectFirst("div[style*=display:none]");
                if (hiddenDate != null) {
                    date = hiddenDate.text().trim();
                }

                if (title.length() > 4) {
                    News news = new News(title, href, date, "");
                    newsList.add(news);
                }
            }
        }

        fetchThumbnails(newsList);

        // 按 link 去重，避免重复新闻
        List<News> result = newsList.stream()
                .distinct()
                .toList();

        // 存入缓存
        CACHE.put(category, new CacheEntry(result));

        return result;
        } finally {
            CACHE_LOCK.writeLock().unlock();
        }
    }

    private void fetchThumbnails(List<News> newsList) {
        ExecutorService executor = Executors.newFixedThreadPool(5);
        for (News news : newsList) {
            executor.submit(() -> {
                try {
                    String thumbnail = fetchFirstImage(news.getLink());
                    if (thumbnail != null && !thumbnail.isEmpty()) {
                        news.setThumbnail(thumbnail);
                    }
                } catch (Exception ignored) {
                }
            });
        }
        executor.shutdown();
        try {
            executor.awaitTermination(30, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private String extractDateFromTitle(String title) {
        // 匹配 "2026年06月01日" 格式
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("^(\\d{4}年\\d{2}月\\d{2}日)");
        java.util.regex.Matcher matcher = pattern.matcher(title);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return "";
    }

    private String fetchFirstImage(String url) {
        try {
            Document doc = fetchDocument(url);

            Elements contentAreas = doc.select(".v_news_content, .article-content, .news-content, #vsb_content, .cont, .c_txt");
            Element contentEl = contentAreas.first();

            if (contentEl != null) {
                Element img = contentEl.selectFirst("img");
                if (img != null) {
                    String src = img.attr("src");
                    if (src != null && !src.isEmpty()) {
                        if (!src.startsWith("http")) {
                            if (src.startsWith("/")) {
                                src = "https://www.glc.edu.cn" + src;
                            } else {
                                src = "https://www.glc.edu.cn/" + src;
                            }
                        }
                        return src;
                    }
                }
            }

            Element bodyImg = doc.selectFirst("body img[src]");
            if (bodyImg != null) {
                String src = bodyImg.attr("src");
                if (src != null && !src.isEmpty()) {
                    if (!src.startsWith("http")) {
                        if (src.startsWith("/")) {
                            src = "https://www.glc.edu.cn" + src;
                        } else {
                            src = "https://www.glc.edu.cn/" + src;
                        }
                    }
                    if (!src.contains("logo") && !src.contains("icon") && !src.contains("banner")) {
                        return src;
                    }
                }
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    public Map<String, String> fetchNewsDetail(String url) throws IOException {
        Document doc = fetchDocument(url);

        Map<String, String> detail = new HashMap<>();

        Element titleEl = doc.selectFirst("h1, h2, .article-title, .news-title, .content_title h1");
        if (titleEl != null) {
            detail.put("title", titleEl.text().trim());
        }

        Elements contentAreas = doc.select(".v_news_content, .article-content, .news-content, #vsb_content, .cont, .c_txt");
        Element contentEl = contentAreas.first();

        if (contentEl != null) {
            contentEl.select("script, style, iframe").remove();

            Elements images = contentEl.select("img");
            for (Element img : images) {
                String src = img.attr("src");
                if (src != null && !src.isEmpty() && !src.startsWith("http")) {
                    if (src.startsWith("/")) {
                        src = "https://www.glc.edu.cn" + src;
                    } else {
                        src = "https://www.glc.edu.cn/" + src;
                    }
                    img.attr("src", src);
                }
            }

            detail.put("content", contentEl.html());

            Element firstImg = contentEl.selectFirst("img");
            if (firstImg != null) {
                detail.put("thumbnail", firstImg.attr("src"));
            }
        } else {
            Element body = doc.selectFirst("body");
            if (body != null) {
                body.select("script, style, nav, header, footer, .header, .footer, .nav").remove();
                detail.put("content", body.html());
            }
        }

        detail.put("url", url);

        return detail;
    }

    public Map<String, String> getAllCategories() {
        return new HashMap<>(CATEGORY_MAP);
    }
}
