package com.guilin.news.crawler;

import com.guilin.news.config.AppConfig;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

import java.io.IOException;

/**
 * HTML 抓取器：集中 Jsoup 连接、UA、超时与编码处理。
 *
 * <p>官网页面声明 UTF-8，但 Jsoup 自动检测偶发失败，故获取原始字节后强制按
 * UTF-8 解码，彻底规避中文乱码。</p>
 */
public class HtmlFetcher {

    /**
     * 抓取并解析目标页面为 Jsoup {@link Document}。
     *
     * @throws IOException 网络或解析失败时
     */
    public Document fetch(String url) throws IOException {
        Connection.Response response = Jsoup.connect(url)
                .userAgent(AppConfig.USER_AGENT)
                .timeout(AppConfig.FETCH_TIMEOUT_MS)
                .execute();
        byte[] bytes = response.bodyAsBytes();
        return Jsoup.parse(new String(bytes, AppConfig.SITE_CHARSET), url);
    }
}
