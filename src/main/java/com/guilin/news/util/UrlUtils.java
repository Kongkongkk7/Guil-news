package com.guilin.news.util;

import com.guilin.news.config.AppConfig;

import java.net.URI;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * URL 处理工具：图片相对路径绝对化、SSRF 白名单校验。
 */
public final class UrlUtils {

    private static final Logger LOGGER = Logger.getLogger(UrlUtils.class.getName());

    private UrlUtils() {
    }

    /**
     * 将图片 src 补全为绝对地址。
     *
     * <p>逻辑与重构前 {@code fetchFirstImage}/{@code fetchNewsDetail} 中的图片处理一致：
     * 已是 http(s) 原样返回；以 {@code /} 开头拼接域名；否则视为相对路径拼接域名加斜杠。</p>
     */
    public static String absolutizeImage(String src) {
        if (src == null || src.isEmpty() || src.startsWith("http")) {
            return src;
        }
        if (src.startsWith("/")) {
            return AppConfig.BASE_URL + src;
        }
        return AppConfig.BASE_URL + "/" + src;
    }

    /**
     * SSRF 防护：仅放行桂林学院官网域名（含子域）。
     *
     * <p>前端对外部链接（如微信公众号）本就直接新标签打开、不走后端，
     * 因此本校验对正常流程零影响，仅堵住通过 {@code url} 参数让服务端抓取任意地址。</p>
     */
    public static boolean isAllowed(String url) {
        if (url == null || url.isEmpty()) {
            return false;
        }
        try {
            String host = URI.create(url).getHost();
            if (host == null) {
                return false;
            }
            host = host.toLowerCase();
            return host.equals(AppConfig.ALLOWED_HOST_SUFFIX)
                    || host.endsWith("." + AppConfig.ALLOWED_HOST_SUFFIX);
        } catch (RuntimeException e) {
            LOGGER.log(Level.FINE, "非法 URL: " + url, e);
            return false;
        }
    }
}
