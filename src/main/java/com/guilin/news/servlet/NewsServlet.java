package com.guilin.news.servlet;

import com.guilin.news.model.News;
import com.guilin.news.service.NewsService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

@WebServlet("/news/*")
public class NewsServlet extends HttpServlet {

    private NewsService newsService = new NewsService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();

        if (pathInfo == null || pathInfo.equals("/")) {
            request.setAttribute("categories", newsService.getAllCategories());
            request.getRequestDispatcher("/jsp/index.jsp").forward(request, response);
            return;
        }

        String category = pathInfo.substring(1);

        try {
            String categoryName = NewsService.getCategoryName(category);
            List<News> newsList = newsService.fetchNews(category);

            request.setAttribute("category", category);
            request.setAttribute("categoryName", categoryName);
            request.setAttribute("newsList", newsList);
            request.setAttribute("categories", newsService.getAllCategories());

            request.getRequestDispatcher("/jsp/news.jsp").forward(request, response);

        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "未知的新闻分类");
        } catch (IOException e) {
            request.setAttribute("error", "获取新闻失败: " + e.getMessage());
            request.setAttribute("categories", newsService.getAllCategories());
            request.getRequestDispatcher("/jsp/error.jsp").forward(request, response);
        }
    }
}
