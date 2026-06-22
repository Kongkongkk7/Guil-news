package com.guilin.news.service;

import com.guilin.news.cache.NewsCache;
import com.guilin.news.common.ApiException;
import com.guilin.news.config.AppConfig;
import com.guilin.news.crawler.HtmlFetcher;
import com.guilin.news.crawler.NewsDetailParser;
import com.guilin.news.crawler.NewsListParser;
import com.guilin.news.model.Category;
import com.guilin.news.model.News;
import com.guilin.news.model.NewsDetail;
import com.guilin.news.util.UrlUtils;
import org.jsoup.nodes.Document;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

/**
 * 新闻服务编排层。
 *
 * <p>负责协调缓存、抓取、解析与并发缩略图补全，自身不含具体的抓取/解析细节。
 * 持有一个可复用的共享线程池用于缩略图并发抓取（替代重构前每次请求 new 一个池的反模式），
 * 线程池由 {@code AppContextListener} 在应用关闭时优雅释放。</p>
 */
public class NewsService {

    private static final Logger LOGGER = Logger.getLogger(NewsService.class.getName());

    private final HtmlFetcher fetcher = new HtmlFetcher();
    private final NewsListParser listParser = new NewsListParser();
    private final NewsDetailParser detailParser = new NewsDetailParser();
    private final NewsCache<String, List<News>> cache = new NewsCache<>();
    private final ExecutorService thumbnailPool =
            Executors.newFixedThreadPool(AppConfig.THUMBNAIL_POOL_SIZE);

    /** 获取指定分类的新闻列表（带缓存）。 */
    public List<News> fetchNews(String categoryKey) throws IOException {
        Category category = Category.fromKey(categoryKey);
        return cache.getOrLoad(categoryKey, () -> loadNews(category));
    }

    /** 缓存未命中时的实际加载逻辑：抓取列表页 → 解析 → 并发补全缩略图 → 去重。 */
    private List<News> loadNews(Category category) throws IOException {
        Document doc = fetcher.fetch(category.getListUrl());
        List<News> newsList = listParser.parse(doc);
        fillThumbnails(newsList);
        return newsList.stream().distinct().collect(Collectors.toList());
    }

    /** 并发为每条新闻补全缩略图，单条失败不影响整体；总等待时间受限。 */
    private void fillThumbnails(List<News> newsList) {
        List<Callable<Void>> tasks = new ArrayList<>(newsList.size());
        for (News news : newsList) {
            tasks.add(() -> {
                String thumbnail = fetchFirstImageSafe(news.getLink());
                if (thumbnail != null && !thumbnail.isEmpty()) {
                    news.setThumbnail(thumbnail);
                }
                return null;
            });
        }
        invokeAllQuietly(tasks);
    }

    /** 批量抓取缩略图（供 {@code POST /api/news/thumbnails}）。非白名单链接跳过。 */
    public Map<String, String> fetchThumbnails(List<String> urls) {
        if (urls == null || urls.isEmpty()) {
            return Collections.emptyMap();
        }
        Map<String, String> results = new ConcurrentHashMap<>();
        List<Callable<Void>> tasks = urls.stream()
                .filter(UrlUtils::isAllowed)
                .map(url -> (Callable<Void>) () -> {
                    String thumbnail = fetchFirstImageSafe(url);
                    if (thumbnail != null && !thumbnail.isEmpty()) {
                        results.put(url, thumbnail);
                    }
                    return null;
                })
                .collect(Collectors.toList());
        invokeAllQuietly(tasks);
        return results;
    }

    /** 获取新闻详情。非白名单链接拒绝抓取（SSRF 防护）。 */
    public NewsDetail fetchNewsDetail(String url) throws IOException {
        if (!UrlUtils.isAllowed(url)) {
            throw new ApiException("不支持的链接");
        }
        Document doc = fetcher.fetch(url);
        return detailParser.parseDetail(doc, url);
    }

    /** 全部分类的 key→列表页 URL 映射。 */
    public Map<String, String> getAllCategories() {
        return Category.asKeyUrlMap();
    }

    /** 应用关闭时释放共享线程池。 */
    public void shutdown() {
        thumbnailPool.shutdown();
        try {
            if (!thumbnailPool.awaitTermination(5, TimeUnit.SECONDS)) {
                thumbnailPool.shutdownNow();
            }
        } catch (InterruptedException e) {
            thumbnailPool.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }

    /** 抓取单页首图，失败记日志并返回 null（保留"单条失败不影响整体"语义）。 */
    private String fetchFirstImageSafe(String url) {
        if (!UrlUtils.isAllowed(url)) {
            return null;
        }
        try {
            Document doc = fetcher.fetch(url);
            return detailParser.extractFirstImage(doc);
        } catch (Exception e) {
            LOGGER.log(Level.FINE, "抓取缩略图失败: " + url, e);
            return null;
        }
    }

    /** 用共享线程池并发执行任务，整体等待时间受限；中断安全。 */
    private void invokeAllQuietly(List<Callable<Void>> tasks) {
        if (tasks.isEmpty()) {
            return;
        }
        try {
            thumbnailPool.invokeAll(tasks, AppConfig.THUMBNAIL_AWAIT_SECONDS, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
