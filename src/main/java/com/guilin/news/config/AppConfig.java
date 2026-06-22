package com.guilin.news.config;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;

/**
 * 应用级配置常量集中地。
 *
 * <p>原先散落在 {@code NewsService} 各处的魔法值（基础域名、UA、超时、缓存 TTL、
 * 线程池大小等）统一收敛到此处，便于调整与维护。</p>
 */
public final class AppConfig {

    private AppConfig() {
    }

    /** 桂林学院官网基础地址，用于相对链接补全。 */
    public static final String BASE_URL = "https://www.glc.edu.cn";

    /** 允许服务端抓取的主机白名单后缀（SSRF 防护）。 */
    public static final String ALLOWED_HOST_SUFFIX = "glc.edu.cn";

    /** 官网页面声明 UTF-8，但 Jsoup 自动检测偶发失败，故强制使用 UTF-8 解码。 */
    public static final Charset SITE_CHARSET = StandardCharsets.UTF_8;

    /** 抓取使用的 User-Agent。 */
    public static final String USER_AGENT =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36";

    /** 单次 HTTP 抓取超时（毫秒）。 */
    public static final int FETCH_TIMEOUT_MS = 10_000;

    /** 列表缓存有效期（毫秒），在实时性与官网负载之间取平衡。 */
    public static final long CACHE_TTL_MS = 5 * 60 * 1000L;

    /** 缩略图并发抓取线程池大小。 */
    public static final int THUMBNAIL_POOL_SIZE = 5;

    /** 缩略图批量抓取的最大等待时间（秒）。 */
    public static final int THUMBNAIL_AWAIT_SECONDS = 30;
}
