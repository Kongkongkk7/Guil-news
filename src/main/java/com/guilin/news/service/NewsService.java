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

public class NewsService {

    private static final Map<String, String> CATEGORY_MAP = new HashMap<>();

    static {
        CATEGORY_MAP.put("xxxw", "https://www.glc.edu.cn/xwzx/xxxw.htm");
        CATEGORY_MAP.put("xsdt", "https://www.glc.edu.cn/xwzx/xsdt.htm");
        CATEGORY_MAP.put("gyrw", "https://www.glc.edu.cn/xwzx/gyrw.htm");
        CATEGORY_MAP.put("mtgy", "https://www.glc.edu.cn/xwzx/mtgy.htm");
    }

    public static String getCategoryName(String category) {
        switch (category) {
            case "xxxw":
                return "校内新闻";
            case "xsdt":
                return "学术动态";
            case "gyrw":
                return "光荣入伍";
            case "mtgy":
                return "媒体关注";
            default:
                return "未知分类";
        }
    }

    public List<News> fetchNews(String category) throws IOException {
        String url = CATEGORY_MAP.get(category);
        if (url == null) {
            throw new IllegalArgumentException("未知的新闻分类: " + category);
        }

        List<News> newsList = new ArrayList<>();

        Document doc = Jsoup.connect(url)
                .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                .timeout(10000)
                .get();

        Elements links = doc.select("a[href*=../info/]");

        for (Element link : links) {
            String title = link.text().trim();
            String href = link.attr("href");

            if (href.startsWith("../info/")) {
                href = href.replace("../", "https://www.glc.edu.cn/");
            }

            String date = "";
            Element parent = link.parent();
            if (parent != null) {
                Elements spans = parent.select("span");
                if (!spans.isEmpty()) {
                    date = spans.last().text().trim();
                }
            }

            if (!title.isEmpty() && !href.isEmpty()) {
                News news = new News(title, href, date);
                newsList.add(news);
            }
        }

        return newsList;
    }

    public Map<String, String> getAllCategories() {
        return new HashMap<>(CATEGORY_MAP);
    }
}
