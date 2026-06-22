package com.guilin.news.listener;

import com.guilin.news.service.NewsService;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import java.util.logging.Logger;

/**
 * 应用生命周期监听器。
 *
 * <p>启动时创建共享的 {@link NewsService} 并放入 {@code ServletContext}，
 * 关闭时优雅释放其内部线程池，避免 Tomcat 关闭/热部署时线程泄漏。</p>
 */
@WebListener
public class AppContextListener implements ServletContextListener {

    /** ServletContext 中存放 NewsService 的属性名。 */
    public static final String NEWS_SERVICE_ATTR = "newsService";

    private static final Logger LOGGER = Logger.getLogger(AppContextListener.class.getName());

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        NewsService service = new NewsService();
        sce.getServletContext().setAttribute(NEWS_SERVICE_ATTR, service);
        LOGGER.info("NewsService 已初始化");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        Object attr = sce.getServletContext().getAttribute(NEWS_SERVICE_ATTR);
        if (attr instanceof NewsService) {
            ((NewsService) attr).shutdown();
            LOGGER.info("NewsService 线程池已释放");
        }
    }
}
