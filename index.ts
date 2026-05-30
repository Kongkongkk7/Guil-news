import { serve } from "bun";
import { Hono } from "hono";
import { cors } from "hono/cors";
import * as cheerio from "cheerio";

const app = new Hono();

app.use("/*", cors());

const CATEGORY_MAP = {
    "xxxw": "https://www.glc.edu.cn/xwzx/xxxw.htm",
    "xsdt": "https://www.glc.edu.cn/xwzx/xsdt.htm",
    "gyrw": "https://www.glc.edu.cn/xwzx/gyrw.htm",
    "mtgy": "https://www.glc.edu.cn/xwzx/mtgy.htm"
};

const fetchNews = async (url: string) => {
    try {
        const response = await fetch(url);
        const html = await response.text();
        const $ = cheerio.load(html);
        const news: any[] = [];

        const newsItems = $('a[href*="../info/"]');
        newsItems.each((i, el) => {
            const a = $(el);
            let link = a.attr('href') || "";
            if (link.startsWith("../info/")) {
                link = link.replace("../", "https://www.glc.edu.cn/");

                let title = a.attr('title') || "";
                if (!title) {
                    title = a.find('h2, h3, h4, strong, .title').text().trim() || a.text().trim().replace(/^[\d年月\s]+/, '').substring(0, 100);
                }

                let dateStr = "";
                const textWithDate = a.text().trim();
                const dateMatch = textWithDate.match(/20\d{2}年\d{2}月\d{2}日/);
                if (dateMatch) {
                    dateStr = dateMatch[0].replace('年', '-').replace('月', '-').replace('日', '');
                }

                if (title && !news.find(n => n.link === link) && title !== "历任校领导" && title !== "现任领导") {
                    news.push({ title, link, date: dateStr });
                }
            }
        });
        return news;
    } catch (e) {
        console.error(e);
        return [];
    }
};

const fetchNewsDetail = async (url: string) => {
    try {
        const response = await fetch(url);
        const html = await response.text();
        const $ = cheerio.load(html);

        const title = $('h1, .article-title, .news-title, .content-title').first().text().trim() ||
                      $('title').text().trim();

        let content = '';
        const contentElement = $('.content, #vsb_content, .article-content, .news-content, .v_news_content').first();

        if (contentElement.length > 0) {
            content = contentElement.html() || '';
        } else {
            content = $('body').html() || '';
        }

        const cleanContent = content
            .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
            .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
            .replace(/window\.addEventListener[^;]*;/g, '')
            .replace(/_showDynClicks\([^)]*\)/g, '')
            .replace(/getImages\([^)]*\)/g, '')
            .replace(/<!--[\s\S]*?-->/g, '')
            .replace(/<input[^>]*>/gi, '')
            .replace(/<form[^>]*>[\s\S]*?<\/form>/gi, '')
            .replace(/<a[^>]*href=["'][^"']*["'][^>]*>([^<]*)<\/a>/gi, '$1')
            .replace(/href=["'][^"']*["']/g, '')
            .replace(/onclick=["'][^"']*["']/g, '')
            .replace(/class=["'][^"']*["']/g, '')
            .replace(/id=["'][^"']*["']/g, '')
            .replace(/\s+class\s*=\s*["'][^"']*["']/gi, '')
            .replace(/<div[^>]*>\s*<\/div>/gi, '')
            .replace(/&nbsp;/g, ' ')
            .replace(/&amp;/g, '&')
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&quot;/g, '"')
            .replace(/&#39;/g, "'")
            .replace(/\s+/g, ' ')
            .trim();

        const baseUrl = 'https://www.glc.edu.cn';
        const processedContent = cleanContent
            .replace(/src=["']\.\.\/\.\.\//g, `src="${baseUrl}/`)
            .replace(/src=["']\.\.\//g, `src="${baseUrl}/`)
            .replace(/src=["']\//g, `src="${baseUrl}/`)
            .replace(/src=["']virtual_attach_file/g, `src="${baseUrl}/virtual_attach_file`);

        return {
            title,
            content: processedContent.substring(0, 10000),
            url
        };
    } catch (e) {
        console.error(e);
        return null;
    }
};

app.get("/api/news", async (c) => {
    const type = c.req.query("type") || "xxxw";
    const url = CATEGORY_MAP[type as keyof typeof CATEGORY_MAP] || CATEGORY_MAP["xxxw"];

    const news = await fetchNews(url);
    return c.json({ success: true, data: news });
});

app.get("/api/news/detail", async (c) => {
    const url = c.req.query("url");
    if (!url) {
        return c.json({ success: false, error: "URL is required" }, 400);
    }

    const detail = await fetchNewsDetail(url);
    if (detail) {
        return c.json({ success: true, data: detail });
    } else {
        return c.json({ success: false, error: "Failed to fetch news detail" }, 500);
    }
});

const startServer = async () => {
    let port = parseInt(process.env.PORT || "4001");
    const maxPort = port + 100;

    while (port <= maxPort) {
        try {
            const server = await serve({
                port,
                fetch: app.fetch,
            });
            console.log(`🚀 后端服务启动成功: http://localhost:${server.port}`);
            break;
        } catch (e) {
            if (port >= maxPort) {
                console.error("❌ 无法找到可用端口");
                process.exit(1);
            }
            port++;
        }
    }
};

startServer();