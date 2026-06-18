package com.guilin.news.servlet;

import com.google.gson.Gson;
import com.guilin.news.model.News;
import com.guilin.news.service.NewsService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

@WebServlet("/api/news/*")
public class ApiServlet extends HttpServlet {

    private NewsService newsService = new NewsService();
    private Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type");

        PrintWriter out = response.getWriter();
        String pathInfo = request.getPathInfo();

        try {
            if (pathInfo == null || pathInfo.equals("/")) {
                String type = request.getParameter("type");
                if (type == null || type.isEmpty()) {
                    Map<String, Object> result = new HashMap<>();
                    result.put("success", true);
                    result.put("data", newsService.getAllCategories());
                    out.print(gson.toJson(result));
                    out.flush();
                    return;
                }

                try {
                    String categoryName = NewsService.getCategoryName(type);
                    List<News> newsList = newsService.fetchNews(type);
                    Map<String, Object> result = new HashMap<>();
                    result.put("success", true);
                    result.put("data", newsList);
                    out.print(gson.toJson(result));
                } catch (IllegalArgumentException e) {
                    Map<String, Object> error = new HashMap<>();
                    error.put("success", false);
                    error.put("message", "未知的新闻分类");
                    out.print(gson.toJson(error));
                } catch (IOException e) {
                    Map<String, Object> error = new HashMap<>();
                    error.put("success", false);
                    error.put("message", "获取新闻失败: " + e.getMessage());
                    out.print(gson.toJson(error));
                }
                out.flush();
                return;
            }

            if (pathInfo.equals("/detail")) {
                String url = request.getParameter("url");
                if (url == null || url.isEmpty()) {
                    response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    Map<String, Object> error = new HashMap<>();
                    error.put("success", false);
                    error.put("message", "缺少 url 参数");
                    out.print(gson.toJson(error));
                    out.flush();
                    return;
                }

                try {
                    Map<String, String> detail = newsService.fetchNewsDetail(url);
                    Map<String, Object> result = new HashMap<>();
                    result.put("success", true);
                    result.put("data", detail);
                    out.print(gson.toJson(result));
                } catch (Exception e) {
                    Map<String, Object> result = new HashMap<>();
                    result.put("success", false);
                    result.put("message", "获取详情失败: " + e.getMessage());
                    out.print(gson.toJson(result));
                }
                out.flush();
                return;
            }

            if (pathInfo.equals("/categories")) {
                Map<String, Object> result = new HashMap<>();
                result.put("success", true);
                result.put("data", newsService.getAllCategories());
                out.print(gson.toJson(result));
                out.flush();
                return;
            }

            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", "未知的 API 路径");
            out.print(gson.toJson(error));

        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", "服务器错误: " + e.getMessage());
            out.print(gson.toJson(error));
        }

        out.flush();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type");

        PrintWriter out = response.getWriter();
        String pathInfo = request.getPathInfo();

        if (pathInfo != null && pathInfo.equals("/thumbnails")) {
            try {
                BufferedReader reader = request.getReader();
                StringBuilder sb = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    sb.append(line);
                }

                Map<String, Object> body = gson.fromJson(sb.toString(), Map.class);
                List<String> urls = (List<String>) body.get("urls");

                Map<String, String> results = new HashMap<>();

                ExecutorService executor = Executors.newFixedThreadPool(5);
                for (String url : urls) {
                    executor.submit(() -> {
                        try {
                            String thumbnail = newsService.fetchFirstImage(url);
                            if (thumbnail != null && !thumbnail.isEmpty()) {
                                synchronized (results) {
                                    results.put(url, thumbnail);
                                }
                            }
                        } catch (Exception ignored) {
                        }
                    });
                }
                executor.shutdown();
                executor.awaitTermination(30, TimeUnit.SECONDS);

                Map<String, Object> result = new HashMap<>();
                result.put("success", true);
                result.put("data", results);
                out.print(gson.toJson(result));

            } catch (Exception e) {
                Map<String, Object> error = new HashMap<>();
                error.put("success", false);
                error.put("message", "获取缩略图失败: " + e.getMessage());
                out.print(gson.toJson(error));
            }
            out.flush();
            return;
        }

        Map<String, Object> error = new HashMap<>();
        error.put("success", false);
        error.put("message", "未知的 API 路径");
        out.print(gson.toJson(error));
        out.flush();
    }
}