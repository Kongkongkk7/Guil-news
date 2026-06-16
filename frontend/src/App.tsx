import { useState, useEffect, useRef } from 'react';
import { NewsItem, NewsCategory, CATEGORIES, CategoryInfo } from './types';

const LOGO_URL = '/logo.png';

const PLACEHOLDER_SVG = `data:image/svg+xml,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 250"><defs><linearGradient id="ph" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" style="stop-color:#e5e7eb"/><stop offset="100%" style="stop-color:#d1d5db"/></linearGradient></defs><rect fill="url(#ph)" width="400" height="250"/><text x="200" y="130" font-family="sans-serif" font-size="16" fill="#9ca3af" text-anchor="middle">暂无图片</text></svg>')}`;

const HERO_BG = `data:image/svg+xml,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 600"><defs><linearGradient id="h1" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" style="stop-color:#0f172a;stop-opacity:1"/><stop offset="30%" style="stop-color:#1E6B56;stop-opacity:1"/><stop offset="70%" style="stop-color:#0D9488;stop-opacity:1"/><stop offset="100%" style="stop-color:#2DD4BF;stop-opacity:1"/></linearGradient></defs><rect fill="url(#h1)" width="1200" height="600"/><circle cx="900" cy="150" r="200" fill="rgba(255,255,255,0.05)"/><circle cx="200" cy="500" r="150" fill="rgba(255,255,255,0.04)"/><path d="M0 500 Q300 400 600 450 T1200 420 L1200 600 L0 600Z" fill="rgba(255,255,255,0.08)"/></svg>')}`;

function App() {
  const [activeCategory, setActiveCategory] = useState<NewsCategory>(() => {
    const params = new URLSearchParams(window.location.search);
    const cat = params.get('category');
    if (cat && ['xxxw', 'xsdt', 'gyrw', 'mtgy'].includes(cat)) {
      return cat as NewsCategory;
    }
    return 'xxxw';
  });
  const [news, setNews] = useState<NewsItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchInput, setSearchInput] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [currentSlide, setCurrentSlide] = useState(0);
  const [isVisible, setIsVisible] = useState(false);
  const searchRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    fetchNews(activeCategory);
    setIsVisible(false);
    setSearchInput('');
    setSearchTerm('');
    const t = setTimeout(() => setIsVisible(true), 100);
    return () => clearTimeout(t);
  }, [activeCategory]);

  useEffect(() => {
    setCurrentSlide(0);
  }, [activeCategory, searchTerm]);

  useEffect(() => {
    const heroCount = Math.min(news.length, 5);
    if (heroCount > 1) {
      const timer = setInterval(() => {
        setCurrentSlide(prev => (prev + 1) % heroCount);
      }, 5000);
      return () => clearInterval(timer);
    }
  }, [news.length]);

  const fetchNews = async (category: NewsCategory) => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(`/api/news?type=${category}`);
      const data = await response.json();
      if (data.success) {
        const newsList: NewsItem[] = data.data;
        setNews(newsList);

        // 异步获取缩略图
        const urls = newsList.map(n => n.link).filter(Boolean);
        if (urls.length > 0) {
          fetch('/api/news/thumbnails', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ urls })
          })
            .then(r => r.json())
            .then(td => {
              if (td.success && td.data) {
                setNews(prev => prev.map(item => ({
                  ...item,
                  thumbnail: td.data[item.link] || item.thumbnail
                })));
              }
            })
            .catch(() => { /* 缩略图加载失败不影响主功能 */ });
        }
      } else {
        setError('获取新闻失败，请稍后重试');
      }
    } catch {
      setError('网络错误，请检查服务器是否运行');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    setSearchTerm(searchInput.trim());
  };

  const handleSearchKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSearch();
    }
  };

  const clearSearch = () => {
    setSearchInput('');
    setSearchTerm('');
    searchRef.current?.focus();
  };

  const openNews = (item: NewsItem) => {
    const detailUrl = `/news-detail?url=${encodeURIComponent(item.link)}&title=${encodeURIComponent(item.title)}&date=${encodeURIComponent(item.date || '')}&category=${activeCategory}&thumb=${encodeURIComponent(item.thumbnail || '')}`;
    window.open(detailUrl, '_blank');
  };

  const filteredNews = searchTerm
    ? news.filter(item => item.title.toLowerCase().includes(searchTerm.toLowerCase()))
    : news;

  const currentCategoryInfo = CATEGORIES.find(c => c.key === activeCategory);
  const heroNews = filteredNews.slice(0, 5);

  const getCategoryColor = (key: NewsCategory) => {
    const colors: Record<NewsCategory, string> = {
      xxxw: 'from-[#1E6B56] to-[#0D9488]',
      xsdt: 'from-[#7C3AED] to-[#A78BFA]',
      gyrw: 'from-[#2563EB] to-[#60A5FA]',
      mtgy: 'from-[#EA580C] to-[#FB923C]'
    };
    return colors[key] || colors.xxxw;
  };

  const currentYear = new Date().getFullYear();

  const today = new Date().toLocaleDateString('zh-CN', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });

  return (
    <div className="min-h-screen bg-gray-50">
      <style>{`
        @keyframes fadeInUp {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }
        @keyframes shimmer {
          0% { background-position: -200% 0; }
          100% { background-position: 200% 0; }
        }
        .animate-fade-in-up {
          animation: fadeInUp 0.5s ease-out forwards;
        }
        .news-card {
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .news-card:hover {
          transform: translateY(-4px);
          box-shadow: 0 20px 40px rgba(0,0,0,0.1);
        }
        .news-card:hover .card-img {
          transform: scale(1.05);
        }
        .news-card:hover .card-overlay {
          opacity: 1;
        }
        .line-clamp-1 {
          display: -webkit-box;
          -webkit-line-clamp: 1;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }
        .line-clamp-2 {
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }
        .news-content img {
          max-width: 100%;
          height: auto;
          border-radius: 8px;
          margin: 16px 0;
          display: block;
        }
        .news-content p {
          margin-bottom: 14px;
          line-height: 1.9;
          font-size: 16px;
          color: #374151;
        }
        .news-content h1, .news-content h2, .news-content h3 {
          font-weight: 700;
          color: #111827;
          margin: 24px 0 12px;
          line-height: 1.4;
        }
        .news-content h1 { font-size: 24px; }
        .news-content h2 { font-size: 20px; }
        .news-content h3 { font-size: 18px; }
        .news-content table {
          width: 100%;
          border-collapse: collapse;
          margin: 16px 0;
        }
        .news-content td, .news-content th {
          border: 1px solid #e5e7eb;
          padding: 10px 14px;
          text-align: left;
        }
        .news-content th {
          background: #f9fafb;
          font-weight: 600;
        }
      `}</style>

      {/* 顶部信息栏 */}
      <div className="bg-[#1E6B56] text-white py-1.5 text-sm">
        <div className="container mx-auto px-4 flex justify-between items-center">
          <span className="flex items-center gap-2 opacity-80">
            <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            {today}
          </span>
          <div className="flex items-center gap-4 opacity-80">
            <span className="hidden md:inline">向学 · 向善 · 自律 · 自强</span>
            <a href="https://www.glc.edu.cn" target="_blank" rel="noopener noreferrer" className="hover:underline">官网首页</a>
          </div>
        </div>
      </div>

      {/* 主头部 */}
      <header className="bg-white shadow-sm sticky top-0 z-40">
        <div className="container mx-auto px-4 py-3">
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-3 flex-shrink-0">
              <img src={LOGO_URL} alt="桂林学院" className="w-11 h-11" />
              <div>
                <h1 className="text-xl font-bold text-[#1E6B56] leading-tight">桂林学院新闻网</h1>
                <p className="text-xs text-gray-400">Guilin University News</p>
              </div>
            </div>
            <div className="relative w-full max-w-sm">
              <div className="flex">
                <input
                  ref={searchRef}
                  type="text"
                  placeholder="搜索新闻标题..."
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
                  onKeyDown={handleSearchKeyDown}
                  className="flex-1 pl-4 pr-3 py-2.5 border-2 border-gray-200 rounded-l-xl
                           focus:outline-none focus:border-[#1E6B56] transition-colors text-sm
                           text-gray-700 placeholder-gray-400"
                />
                {searchTerm && (
                  <button
                    onClick={clearSearch}
                    className="px-3 py-2.5 bg-gray-100 border-y-2 border-gray-200 text-gray-400 hover:text-gray-600 transition-colors"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                )}
                <button
                  onClick={handleSearch}
                  className="px-5 py-2.5 bg-[#1E6B56] text-white rounded-r-xl hover:bg-[#155545] transition-colors flex items-center gap-1.5"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                  <span className="text-sm font-medium">搜索</span>
                </button>
              </div>
              {searchTerm && (
                <div className="absolute top-full left-0 right-0 mt-1 text-xs text-gray-500 bg-white px-3 py-1.5 rounded-lg shadow-sm border">
                  搜索 "{searchTerm}" 找到 {filteredNews.length} 条结果
                </div>
              )}
            </div>
          </div>
        </div>

        {/* 导航条 */}
        <nav className="bg-[#1E6B56]">
          <div className="container mx-auto px-4">
            <div className="flex overflow-x-auto">
              {CATEGORIES.map((category: CategoryInfo) => (
                <button
                  key={category.key}
                  onClick={() => setActiveCategory(category.key)}
                  className={`
                    px-6 py-3 font-medium whitespace-nowrap transition-all duration-200 relative flex items-center gap-1.5 text-sm
                    ${activeCategory === category.key
                      ? 'bg-white/20 text-white'
                      : 'text-white/70 hover:text-white hover:bg-white/10'
                    }
                  `}
                >
                  <span>{category.icon}</span>
                  <span>{category.label}</span>
                  {activeCategory === category.key && (
                    <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-white rounded-full"></div>
                  )}
                </button>
              ))}
            </div>
          </div>
        </nav>
      </header>

      {/* Hero 轮播 */}
      {!loading && heroNews.length > 0 && (
        <section className="relative h-[360px] lg:h-[420px] overflow-hidden bg-gray-900">
          {heroNews.map((item, index) => (
            <div
              key={index}
              className={`absolute inset-0 transition-all duration-700 ${
                index === currentSlide ? 'opacity-100' : 'opacity-0'
              }`}
            >
              <img
                src={item.thumbnail || HERO_BG}
                alt={item.title}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent"></div>
              <div className="absolute bottom-0 left-0 right-0 container mx-auto px-6 pb-12 z-10">
                <span className="inline-block px-3 py-1 bg-[#1E6B56] text-white text-xs rounded mb-3">
                  {currentCategoryInfo?.label}
                </span>
                <h2
                  className="text-2xl lg:text-3xl font-bold text-white mb-3 cursor-pointer hover:text-[#2DD4BF] transition-colors leading-tight max-w-3xl"
                  onClick={() => openNews(item)}
                >
                  {item.title}
                </h2>
                <div className="flex items-center gap-4 text-white/70 text-sm">
                  <span className="flex items-center gap-1.5">
                    <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    {item.date}
                  </span>
                  <button
                    onClick={() => openNews(item)}
                    className="px-5 py-1.5 bg-white/20 hover:bg-white/30 text-white rounded-full transition-all text-sm backdrop-blur-sm"
                  >
                    阅读全文
                  </button>
                </div>
              </div>
            </div>
          ))}
          <div className="absolute bottom-4 left-1/2 -translate-x-1/2 z-20 flex gap-2">
            {heroNews.map((_, i) => (
              <button key={i} onClick={() => setCurrentSlide(i)}
                className={`transition-all rounded-full ${i === currentSlide ? 'w-7 h-2 bg-white' : 'w-2 h-2 bg-white/40 hover:bg-white/60'}`}
              />
            ))}
          </div>
          <button onClick={() => setCurrentSlide(p => (p - 1 + heroNews.length) % heroNews.length)}
            className="absolute left-3 top-1/2 -translate-y-1/2 z-20 w-10 h-10 bg-black/30 hover:bg-black/50 text-white rounded-full flex items-center justify-center transition-all backdrop-blur-sm">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
          </button>
          <button onClick={() => setCurrentSlide(p => (p + 1) % heroNews.length)}
            className="absolute right-3 top-1/2 -translate-y-1/2 z-20 w-10 h-10 bg-black/30 hover:bg-black/50 text-white rounded-full flex items-center justify-center transition-all backdrop-blur-sm">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
          </button>
        </section>
      )}

      {/* 主内容区 */}
      <main className="container mx-auto px-4 py-10">
        <div className="mb-6 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={`w-1 h-8 bg-gradient-to-b ${getCategoryColor(activeCategory)} rounded-full`}></div>
            <div>
              <h2 className="text-xl font-bold text-gray-800">{currentCategoryInfo?.label}</h2>
              <p className="text-gray-400 text-sm">{currentCategoryInfo?.description}</p>
            </div>
          </div>
          <span className="text-sm text-gray-400">共 {filteredNews.length} 条</span>
        </div>

        {error && (
          <div className="bg-red-50 border-l-4 border-red-400 rounded-lg p-5 mb-6">
            <p className="text-red-600 text-sm">{error}</p>
            <button onClick={() => fetchNews(activeCategory)} className="mt-3 px-4 py-1.5 bg-red-500 text-white text-sm rounded-lg hover:bg-red-600 transition-colors">
              点击重试
            </button>
          </div>
        )}

        {loading && (
          <div className="space-y-4">
            {[1, 2, 3, 4, 5].map(i => (
              <div key={i} className="bg-white rounded-xl overflow-hidden shadow-sm flex h-36">
                <div className="w-56 flex-shrink-0 bg-gradient-to-r from-gray-200 via-gray-100 to-gray-200" style={{ backgroundSize: '200% 100%', animation: 'shimmer 1.5s ease-in-out infinite' }}></div>
                <div className="flex-1 p-5">
                  <div className="h-5 bg-gray-200 rounded w-3/4 mb-3 animate-pulse"></div>
                  <div className="h-4 bg-gray-200 rounded w-1/2 mb-2 animate-pulse"></div>
                  <div className="h-3 bg-gray-200 rounded w-1/4 animate-pulse mt-4"></div>
                </div>
              </div>
            ))}
          </div>
        )}

        {!loading && !error && filteredNews.length === 0 && (
          <div className="bg-white rounded-xl p-16 text-center shadow-sm">
            <svg className="w-16 h-16 mx-auto text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
            </svg>
            <p className="text-gray-400 text-lg">{searchTerm ? `没有找到 "${searchTerm}" 相关的新闻` : '暂无新闻'}</p>
            {searchTerm && (
              <button onClick={clearSearch} className="mt-4 px-4 py-2 text-[#1E6B56] text-sm hover:underline">清除搜索</button>
            )}
          </div>
        )}

        {!loading && !error && filteredNews.length > 0 && (
          <div className={`space-y-3 ${isVisible ? 'animate-fade-in-up' : 'opacity-0'}`}>
            {filteredNews.map((item: NewsItem, index: number) => (
              <article
                key={index}
                onClick={() => openNews(item)}
                className="news-card group bg-white rounded-xl overflow-hidden shadow-sm cursor-pointer flex h-36 lg:h-40 border border-gray-100 hover:border-[#1E6B56]/20"
              >
                <div className="w-52 lg:w-64 flex-shrink-0 overflow-hidden relative">
                  <img
                    src={item.thumbnail || PLACEHOLDER_SVG}
                    alt={item.title}
                    className="card-img w-full h-full object-cover transition-transform duration-500"
                    onError={(e) => { (e.target as HTMLImageElement).src = PLACEHOLDER_SVG; }}
                  />
                  <div className="card-overlay absolute inset-0 bg-[#1E6B56]/10 opacity-0 transition-opacity duration-300"></div>
                </div>
                <div className="flex-1 p-5 flex flex-col justify-between min-w-0">
                  <div>
                    <h3 className="text-base lg:text-lg font-bold text-gray-800 line-clamp-2 leading-relaxed hover:text-[#1E6B56] transition-colors">
                      {item.title}
                    </h3>
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3 text-gray-400 text-xs">
                      <span className="flex items-center gap-1">
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                        </svg>
                        {item.date}
                      </span>
                      <span className="px-2 py-0.5 bg-[#1E6B56]/10 text-[#1E6B56] rounded text-xs">
                        {currentCategoryInfo?.label}
                      </span>
                    </div>
                    <span className="text-[#1E6B56] text-sm font-medium flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      阅读
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                      </svg>
                    </span>
                  </div>
                </div>
              </article>
            ))}
          </div>
        )}
      </main>

      {/* 页脚 */}
      <footer className="bg-gray-900 text-gray-400 mt-8">
        <div className="container mx-auto px-4 py-10">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div>
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 rounded-full overflow-hidden bg-white flex items-center justify-center">
                  <img src={LOGO_URL} alt="校徽" className="w-10 h-10" />
                </div>
                <div>
                  <h3 className="text-white font-bold">桂林学院</h3>
                  <p className="text-xs text-gray-500">Guilin University</p>
                </div>
              </div>
              <p className="text-sm leading-relaxed">桂林山水甲天下，校园文化润人心。</p>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-3">新闻分类</h4>
              <ul className="space-y-1.5">
                {CATEGORIES.map(cat => (
                  <li key={cat.key}>
                    <button onClick={() => { setActiveCategory(cat.key); window.scrollTo({ top: 0, behavior: 'smooth' }); }}
                      className="text-sm hover:text-white transition-colors flex items-center gap-1.5">
                      <span>{cat.icon}</span><span>{cat.label}</span>
                    </button>
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-3">联系我们</h4>
              <div className="space-y-2 text-sm">
                <p className="flex items-center gap-2">
                  <svg className="w-4 h-4 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  广西桂林市雁山区雁中路3号
                </p>
                <p className="flex items-center gap-2">
                  <svg className="w-4 h-4 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                  </svg>
                  0773-3696366
                </p>
                <a href="https://www.glc.edu.cn" target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 hover:text-white transition-colors">
                  <svg className="w-4 h-4 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
                  </svg>
                  www.glc.edu.cn
                </a>
              </div>
            </div>
          </div>
          <div className="border-t border-gray-800 mt-8 pt-5 text-center text-xs text-gray-500">
            © {currentYear} 桂林学院 版权所有 | 新闻中心
          </div>
        </div>
      </footer>

      {/* 详情页已改为新标签页打开 */}
    </div>
  );
}

export default App;
