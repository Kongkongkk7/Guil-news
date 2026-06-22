package com.guilin.news.servlet;

import com.google.gson.Gson;
import com.guilin.news.common.ApiException;
import com.guilin.news.common.ApiResponse;
import com.guilin.news.listener.AppContextListener;
import com.guilin.news.model.News;
import com.guilin.news.model.NewsDetail;
import com.guilin.news.service.NewsService;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * API 控制器（瘦层）：只负责路由、参数提取与响应序列化，业务逻辑全部委托给
 * {@link NewsService}。CORS 由 {@link CorsFilter} 统一处理。
 *
 * <ul>
 *   <li>GET  /api/news?type=xxx     新闻列表（无 type 返回全部分类）</li>
 *   <li>GET  /api/news/detail?url=  新闻详情</li>
 *   <li>GET  /api/news/categories   全部分类</li>
 *   <li>POST /api/news/thumbnails   批量缩略图</li>
 * </ul>
 */
@WebServlet("/api/news/*")
public class ApiServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(ApiServlet.class.getName());
    private static final Gson GSON = new Gson();

    private NewsService newsService;

    @Override
    public void init() {
        // 共享 NewsService 由 AppContextListener 创建并放入 ServletContext
        Object attr = getServletContext().getAttribute(AppContextListener.NEWS_SERVICE_ATTR);
        this.newsService = (attr instanceof NewsService) ? (NewsService) attr : new NewsService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        PrintWriter out = beginJson(response);
        String pathInfo = request.getPathInfo();

        try {
            if (pathInfo == null || pathInfo.equals("/")) {
                handleNewsList(request, out);
            } else if (pathInfo.equals("/detail")) {
                handleDetail(request, response, out);
            } else if (pathInfo.equals("/categories")) {
                write(out, ApiResponse.ok(newsService.getAllCategories()));
            } else {
                write(out, ApiResponse.fail("未知的 API 路径"));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "处理 GET 请求出错", e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            write(out, ApiResponse.fail("服务器错误: " + e.getMessage()));
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        PrintWriter out = beginJson(response);
        String pathInfo = request.getPathInfo();

        if (pathInfo != null && pathInfo.equals("/thumbnails")) {
            handleThumbnails(request, out);
        } else {
            write(out, ApiResponse.fail("未知的 API 路径"));
        }
    }

    // ---- 各端点处理 ----

    private void handleNewsList(HttpServletRequest request, PrintWriter out) {
        String type = request.getParameter("type");
        if (type == null || type.isEmpty()) {
            write(out, ApiResponse.ok(newsService.getAllCategories()));
            return;
        }
        try {
            List<News> newsList = newsService.fetchNews(type);
            write(out, ApiResponse.ok(newsList));
        } catch (ApiException e) {
            write(out, ApiResponse.fail(e.getMessage()));
        } catch (IOException e) {
            LOGGER.log(Level.WARNING, "获取新闻失败: " + type, e);
            write(out, ApiResponse.fail("获取新闻失败: " + e.getMessage()));
        }
    }

    private void handleDetail(HttpServletRequest request, HttpServletResponse response, PrintWriter out) {
        String url = request.getParameter("url");
        if (url == null || url.isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            write(out, ApiResponse.fail("缺少 url 参数"));
            return;
        }
        try {
            NewsDetail detail = newsService.fetchNewsDetail(url);
            write(out, ApiResponse.ok(detail));
        } catch (ApiException e) {
            write(out, ApiResponse.fail(e.getMessage()));
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "获取详情失败: " + url, e);
            write(out, ApiResponse.fail("获取详情失败: " + e.getMessage()));
        }
    }

    @SuppressWarnings("unchecked")
    private void handleThumbnails(HttpServletRequest request, PrintWriter out) {
        try {
            StringBuilder sb = new StringBuilder();
            try (BufferedReader reader = request.getReader()) {
                String line;
                while ((line = reader.readLine()) != null) {
                    sb.append(line);
                }
            }
            Map<String, Object> body = GSON.fromJson(sb.toString(), Map.class);
            List<String> urls = body == null ? null : (List<String>) body.get("urls");
            write(out, ApiResponse.ok(newsService.fetchThumbnails(urls)));
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "获取缩略图失败", e);
            write(out, ApiResponse.fail("获取缩略图失败: " + e.getMessage()));
        }
    }

    // ---- 工具方法 ----

    private PrintWriter beginJson(HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        return response.getWriter();
    }

    private void write(PrintWriter out, ApiResponse<?> body) {
        out.print(GSON.toJson(body));
        out.flush();
    }
}
