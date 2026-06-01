import { useState, useEffect, useRef } from 'react';

interface NewsDetail {
  title: string;
  content: string;
  url: string;
  thumbnail?: string;
}

const LOGO_URL = '/logo.png';
const HERO_BG = `data:image/svg+xml,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 600"><defs><linearGradient id="h1" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" style="stop-color:#0f172a;stop-opacity:1"/><stop offset="30%" style="stop-color:#1E6B56;stop-opacity:1"/><stop offset="70%" style="stop-color:#0D9488;stop-opacity:1"/><stop offset="100%" style="stop-color:#2DD4BF;stop-opacity:1"/></linearGradient></defs><rect fill="url(#h1)" width="1200" height="600"/><circle cx="900" cy="150" r="200" fill="rgba(255,255,255,0.05)"/><circle cx="200" cy="500" r="150" fill="rgba(255,255,255,0.04)"/><path d="M0 500 Q300 400 600 450 T1200 420 L1200 600 L0 600Z" fill="rgba(255,255,255,0.08)"/></svg>')}`;

const CATEGORY_LABELS: Record<string, string> = {
  xxxw: '桂院要闻',
  xsdt: '学术动态',
  xykx: '校园快讯'
};

function NewsDetailPage() {
  const [detail, setDetail] = useState<NewsDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [fontSize, setFontSize] = useState(16);
  const [progress, setProgress] = useState(0);
  const [showBackTop, setShowBackTop] = useState(false);
  const printRef = useRef<HTMLDivElement>(null);
  const currentYear = new Date().getFullYear();

  const params = new URLSearchParams(window.location.search);
  const url = params.get('url') || '';
  const title = params.get('title') || '新闻详情';
  const date = params.get('date') || '';
  const category = params.get('category') || 'xxxw';
  const thumb = params.get('thumb') || '';

  const goTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  useEffect(() => {
    document.title = `${title} - 桂林学院新闻网`;
    document.body.style.background = '#f3f4f6';

    const fetchDetail = async () => {
      if (!url) {
        setError('参数错误');
        setLoading(false);
        return;
      }
      setLoading(true);
      setError(null);
      try {
        const response = await fetch(`/api/news/detail?url=${encodeURIComponent(url)}`);
        const data = await response.json();
        if (data.success && data.detail) {
          setDetail(data.detail);
        } else {
          setError('获取详情失败');
        }
      } catch {
        setError('网络错误');
      } finally {
        setLoading(false);
      }
    };
    fetchDetail();

    const onScroll = () => {
      const sc = window.scrollY;
      const total = document.documentElement.scrollHeight - window.innerHeight;
      setProgress(total > 0 ? (sc / total) * 100 : 0);
      setShowBackTop(sc > 400);
    };
    window.addEventListener('scroll', onScroll);
    return () => {
      window.removeEventListener('scroll', onScroll);
      document.title = '桂林学院新闻网';
      document.body.style.background = '';
    };
  }, [url, title]);

  const categoryLabel = CATEGORY_LABELS[category] || '桂院要闻';
  const finalThumb = detail?.thumbnail || thumb || HERO_BG;
  const plainTextContent = detail?.content?.replace(/<[^>]*>/g, '') || '';
  const readingTime = Math.max(1, Math.ceil(plainTextContent.length / 400));

  return (
    <div className="min-h-screen bg-gray-50">
      <style>{`
        .news-content {
          font-size: ${fontSize}px;
          line-height: 1.95;
          color: #1f2937;
        }
        .news-content img {
          max-width: 100%;
          height: auto;
          border-radius: 10px;
          margin: 24px auto;
          display: block;
          box-shadow: 0 6px 20px rgba(0,0,0,0.08);
        }
        .news-content p {
          margin-bottom: 18px;
          text-indent: 2em;
          text-align: justify;
        }
        .news-content h1, .news-content h2, .news-content h3, .news-content h4 {
          font-weight: 700;
          color: #0F5A52;
          margin: 28px 0 14px;
          line-height: 1.5;
        }
        .news-content h1 { font-size: 1.6em; text-align: center; }
        .news-content h2 { font-size: 1.35em; border-left: 4px solid #1E6B56; padding-left: 12px; }
        .news-content h3 { font-size: 1.18em; color: #1E6B56; }
        .news-content table {
          width: 100%;
          border-collapse: collapse;
          margin: 20px 0;
          font-size: 0.95em;
        }
        .news-content td, .news-content th {
          border: 1px solid #d1d5db;
          padding: 10px 14px;
          text-align: left;
        }
        .news-content th {
          background: #f3f4f6;
          font-weight: 600;
        }
        .news-content blockquote {
          margin: 20px 0;
          padding: 14px 20px;
          border-left: 4px solid #C9A961;
          background: #fafaf5;
          color: #555;
          font-style: italic;
        }
        .news-content strong { color: #0F5A52; }
        .news-content a { color: #1E6B56; text-decoration: underline; }
        .news-content ul, .news-content ol {
          margin: 14px 0 14px 24px;
          padding-left: 14px;
        }
        .news-content li { margin-bottom: 6px; }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        .fade-in { animation: fadeIn 0.5s ease-out; }
        @media print {
          header, .sticky, footer, button { display: none !important; }
          .news-content { font-size: 14px !important; }
          .news-content p { text-indent: 2em; }
          .container { max-width: 100% !important; padding: 0 !important; }
          article { box-shadow: none !important; padding: 0 !important; }
          body { background: white !important; }
        }
      `}</style>

      {/* 顶部导航条 */}
      <header className="bg-white shadow-sm sticky top-0 z-50 border-b border-gray-200">
        <div className="container mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <a href="/" className="flex items-center gap-3 hover:opacity-90 transition-opacity">
              <img src={LOGO_URL} alt="桂林学院" className="w-10 h-10" />
              <div>
                <h1 className="text-base font-bold text-[#1E6B56] leading-tight">桂林学院新闻网</h1>
                <p className="text-xs text-gray-400">Guilin University News</p>
              </div>
            </a>
            <div className="hidden sm:flex items-center gap-2 ml-4 border-l border-gray-200 pl-4">
              <span className="text-xs text-gray-400">快速访问</span>
              {['xxxw', 'xsdt', 'xykx'].map(cat => (
                <a key={cat} href={`/?category=${cat}`}
                  className={`px-2.5 py-1 rounded text-xs ${category === cat ? 'bg-[#1E6B56] text-white' : 'text-gray-500 hover:bg-gray-100'}`}>
                  {CATEGORY_LABELS[cat]}
                </a>
              ))}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <a href="/"
              className="flex items-center gap-1.5 px-3 py-1.5 bg-[#1E6B56]/10 text-[#1E6B56] rounded-lg hover:bg-[#1E6B56]/20 transition-colors text-sm font-medium">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              返回首页
            </a>
          </div>
        </div>
        {/* 阅读进度条 */}
        <div className="h-1 bg-gray-100">
          <div className="h-full bg-gradient-to-r from-[#1E6B56] to-[#2DD4BF] transition-all duration-150"
            style={{ width: `${progress}%` }}></div>
        </div>
      </header>

      {/* Hero 头图 */}
      <div className="relative h-[300px] lg:h-[380px] overflow-hidden bg-gray-900">
        <img src={finalThumb} alt={title} className="w-full h-full object-cover"
          onError={(e) => { (e.target as HTMLImageElement).src = HERO_BG; }} />
        <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/40 to-transparent"></div>
        <div className="absolute bottom-0 left-0 right-0 container mx-auto px-6 pb-10 z-10">
          <div className="flex items-center gap-2 mb-3">
            <span className="inline-block px-3 py-1 bg-[#1E6B56] text-white text-xs rounded font-medium">
              {categoryLabel}
            </span>
            <span className="text-white/60 text-xs flex items-center gap-1">
              <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              {date}
            </span>
          </div>
          <h1 className="text-2xl lg:text-3xl font-bold text-white leading-tight max-w-4xl">
            {title}
          </h1>
        </div>
      </div>

      {/* 工具栏 */}
      <div className="bg-white border-b border-gray-200 sticky top-[60px] z-40">
        <div className="container mx-auto px-4 py-2 flex items-center justify-between text-sm">
          <div className="flex items-center gap-3 text-gray-500">
            <span className="flex items-center gap-1">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              阅读时间 约 {readingTime} 分钟
            </span>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-gray-500">字号:</span>
            <div className="flex border border-gray-200 rounded-lg overflow-hidden">
              <button onClick={() => setFontSize(Math.max(14, fontSize - 1))}
                className="w-8 h-8 hover:bg-gray-100 text-gray-600 transition-colors">A-</button>
              <span className="w-8 h-8 flex items-center justify-center border-x border-gray-200 text-[#1E6B56] font-medium">
                {fontSize}
              </span>
              <button onClick={() => setFontSize(Math.min(22, fontSize + 1))}
                className="w-8 h-8 hover:bg-gray-100 text-gray-600 transition-colors">A+</button>
            </div>
            <button onClick={() => window.print()}
              className="w-8 h-8 hover:bg-gray-100 text-gray-600 rounded-lg transition-colors flex items-center justify-center"
              title="打印">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
              </svg>
            </button>
          </div>
        </div>
      </div>

      {/* 内容主体 */}
      <main className="container mx-auto px-4 py-8 max-w-4xl">
        <article className="bg-white rounded-2xl shadow-sm p-6 lg:p-10 fade-in" ref={printRef}>
          {loading && (
            <div className="space-y-4 py-8">
              {[1, 2, 3, 4, 5, 6, 7].map(i => (
                <div key={i} className="animate-pulse">
                  <div className="h-4 bg-gray-200 rounded" style={{ width: `${Math.max(40, 100 - i * 10)}%` }}></div>
                </div>
              ))}
            </div>
          )}

          {!loading && detail && (
            <div className="news-content" dangerouslySetInnerHTML={{ __html: detail.content }} />
          )}

          {!loading && error && (
            <div className="text-center py-10">
              <svg className="w-16 h-16 mx-auto text-gray-300 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
              <p className="text-gray-400 mb-4">{error}</p>
            </div>
          )}
        </article>

        {/* 来源于 */}
        <div className="mt-6 text-center">
          <span className="text-gray-500 text-sm">
            来源于：<a href={url} target="_blank" rel="noopener noreferrer"
              className="text-[#1E6B56] hover:text-[#0D9488] hover:underline transition-colors font-medium">
              桂林学院官方网站
              <svg className="w-3 h-3 inline-block ml-0.5 -mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </a>
          </span>
        </div>
      </main>

      {/* 返回顶部按钮 */}
      <button onClick={goTop}
        className={`fixed bottom-6 right-6 z-50 w-12 h-12 bg-[#1E6B56] text-white rounded-full shadow-lg hover:bg-[#155545] transition-all duration-300 flex items-center justify-center ${showBackTop ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4 pointer-events-none'}`}
        title="返回顶部">
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 15l7-7 7 7" />
        </svg>
      </button>

      {/* 页脚 */}
      <footer className="bg-gray-900 text-gray-400 mt-12 py-6">
        <div className="container mx-auto px-4 text-center text-xs">
          © {currentYear} 桂林学院 版权所有 · 新闻中心
        </div>
      </footer>
    </div>
  );
}

export default NewsDetailPage;
