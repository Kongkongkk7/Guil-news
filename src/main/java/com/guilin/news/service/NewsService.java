package com.guilin.news.service;

import com.guilin.news.model.News;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import java.io.IOException;
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
            default:
                return "未知分类";
        }
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

            Document doc = Jsoup.connect(url)
                .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                .timeout(10000)
                .get();

        Elements newsItems = doc.select("li, .news-item, .list-item");

        for (Element item : newsItems) {
            // 查找新闻链接：内部链接、微信链接
            Element linkEl = item.selectFirst("a[href*=info/], a[href*=mp.weixin]");
            if (linkEl == null) continue;

            String title = linkEl.text().trim();
            String href = linkEl.attr("href");

            // 处理相对路径
            if (href.startsWith("../")) {
                href = href.replace("../", "https://www.glc.edu.cn/");
            } else if (href.startsWith("/") && !href.startsWith("//")) {
                href = "https://www.glc.edu.cn" + href;
            } else if (!href.startsWith("http")) {
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

            // 清理标题中的日期前缀和多余空格
            String cleanTitle = title.replaceFirst("^\\d{4}年\\d{2}月\\d{2}日\\s*", "").trim();

            if (!cleanTitle.isEmpty() && !href.isEmpty()
                    && !cleanTitle.contains("历任校领导")
                    && !cleanTitle.contains("信息公开")
                    && cleanTitle.length() > 4) {
                News news = new News(cleanTitle, href, date, "");
                newsList.add(news);
            }
        }

        if (newsList.isEmpty()) {
            // 通用解析：匹配所有有意义的链接（包括微信链接、内部链接等）
            Elements allLinks = doc.select("a[href]");
            for (Element link : allLinks) {
                String title = link.text().trim();
                String href = link.attr("href");

                // 跳过空链接、导航链接、图片链接
                if (title.isEmpty() || href.isEmpty() || title.length() < 4) continue;
                if (href.equals("#") || href.startsWith("javascript:") || href.startsWith("mailto:")) continue;
                if (title.contains("首页") || title.contains("上页") || title.contains("下页") 
                        || title.contains("尾页") || title.contains("跳转")) continue;

                // 处理相对路径
                if (href.startsWith("../")) {
                    href = href.replace("../", "https://www.glc.edu.cn/");
                } else if (href.startsWith("/") && !href.startsWith("//")) {
                    href = "https://www.glc.edu.cn" + href;
                }

                // 只保留有意义的新闻链接（排除分类页面、导航页面等）
                if (href.contains("info/") || href.contains("mp.weixin.qq.com")) {
                    // 从标题中提取日期
                    String date = extractDateFromTitle(title);
                    String cleanTitle = title.replaceFirst("^\\d{4}年\\d{2}月\\d{2}日\\s*", "").trim();

                    if (!cleanTitle.isEmpty() && cleanTitle.length() > 4
                            && !cleanTitle.contains("历任校领导")
                            && !cleanTitle.contains("信息公开")) {
                        News news = new News(cleanTitle, href, date, "");
                        newsList.add(news);
                    }
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

    public String fetchFirstImage(String url) {
        try {
            Document doc = Jsoup.connect(url)
                    .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                    .timeout(8000)
                    .get();

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
        Map<String, String> detail = new HashMap<>();
        detail.put("url", url);

        // 微信公众号链接：尝试解析文章内容
        if (url.contains("mp.weixin.qq.com")) {
            try {
                Document wxDoc = Jsoup.connect(url)
                        .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                        .header("Accept", "text/html,application/xhtml+xml")
                        .header("Accept-Language", "zh-CN,zh;q=0.9")
                        .timeout(15000)
                        .get();

                // 提取标题
                Element wxTitle = wxDoc.selectFirst("#activity-name, .rich_media_title");
                if (wxTitle != null) {
                    detail.put("title", wxTitle.text().trim());
                }

                // 提取内容
                Element wxContent = wxDoc.selectFirst("#js_content, .rich_media_content");
                if (wxContent != null) {
                    wxContent.select("script, style, iframe").remove();

                    // 处理微信图片：data-src -> src
                    Elements wxImages = wxContent.select("img");
                    for (Element img : wxImages) {
                        String dataSrc = img.attr("data-src");
                        if (!dataSrc.isEmpty()) {
                            img.attr("src", dataSrc);
                        }
                        // 移除懒加载属性
                        img.removeAttr("data-src");
                        img.removeAttr("loading");
                    }

                    String contentHtml = wxContent.html();
                    if (contentHtml.length() > 50) {
                        detail.put("content", contentHtml);

                        // 提取第一张图作为缩略图
                        Element firstImg = wxContent.selectFirst("img[src]");
                        if (firstImg != null) {
                            detail.put("thumbnail", firstImg.attr("src"));
                        }
                        return detail;
                    }
                }
            } catch (Exception ignored) {
            }

            // 解析失败，返回引导跳转卡片
            detail.put("title", "微信公众号文章");
            detail.put("content", "<div style='text-align:center;padding:60px 20px;max-width:500px;margin:0 auto;'>"
                + "<div style='width:64px;height:64px;margin:0 auto 24px;background:#07C160;border-radius:16px;"
                + "display:flex;align-items:center;justify-content:center;'>"
                + "<svg width='32' height='32' viewBox='0 0 24 24' fill='white'>"
                + "<path d='M9.5 4C5.36 4 2 6.69 2 10c0 1.89 1.08 3.56 2.78 4.66L4 17l2.83-1.55C7.53 15.65 8.5 16 9.5 16c.17 0 .33 0 .5-.02C9.68 15.4 9.5 14.71 9.5 14c0-3.31 3.36-6 7.5-6 .17 0 .33 0 .5.02C16.93 5.77 13.5 4 9.5 4zM7 8.5c.55 0 1 .45 1 1s-.45 1-1 1-1-.45-1-1 .45-1 1-1zm5 0c.55 0 1 .45 1 1s-.45 1-1 1-1-.45-1-1 .45-1 1-1z'/>"
                + "</svg></div>"
                + "<h2 style='font-size:20px;color:#1f2937;margin-bottom:12px;font-weight:600;'>微信公众号文章</h2>"
                + "<p style='color:#6b7280;font-size:15px;margin-bottom:28px;line-height:1.6;'>本文来自微信公众号，由于平台限制，请在微信中查看完整内容</p>"
                + "<a href='" + url + "' target='_blank' "
                + "style='display:inline-block;padding:14px 40px;background:#1E6B56;color:#fff;"
                + "border-radius:10px;text-decoration:none;font-size:16px;font-weight:500;"
                + "box-shadow:0 4px 12px rgba(30,107,86,0.3);transition:all 0.3s;'>"
                + "点击阅读全文</a></div>");
            return detail;
        }

        Document doc = Jsoup.connect(url)
                .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                .timeout(10000)
                .get();

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

        return detail;
    }

    public Map<String, String> getAllCategories() {
        return new HashMap<>(CATEGORY_MAP);
    }
}
