import { useState, useEffect } from 'react';
import { NewsItem, NewsCategory, CATEGORIES, CategoryInfo } from './types';

interface NewsDetail {
  title: string;
  content: string;
  url: string;
}

function App() {
  const [activeCategory, setActiveCategory] = useState<NewsCategory>('xxxw');
  const [news, setNews] = useState<NewsItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedNews, setSelectedNews] = useState<NewsItem | null>(null);
  const [newsDetail, setNewsDetail] = useState<NewsDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchNews(activeCategory);
  }, [activeCategory]);

  const fetchNews = async (category: NewsCategory) => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(`/api/news?type=${category}`);
      const data = await response.json();
      if (data.success) {
        setNews(data.data);
      } else {
        setError('获取新闻失败，请稍后重试');
      }
    } catch (err) {
      setError('网络错误，请检查服务器是否运行');
    } finally {
      setLoading(false);
    }
  };

  const fetchNewsDetail = async (url: string) => {
    setDetailLoading(true);
    setNewsDetail(null);
    try {
      const response = await fetch(`/api/news/detail?url=${encodeURIComponent(url)}`);
      const data = await response.json();
      if (data.success) {
        setNewsDetail(data.data);
      }
    } catch (err) {
      console.error('Failed to fetch news detail:', err);
    } finally {
      setDetailLoading(false);
    }
  };

  const closeDetail = () => {
    setSelectedNews(null);
    setNewsDetail(null);
  };

  const filteredNews = news.filter(item =>
    item.title.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const currentCategoryInfo = CATEGORIES.find(c => c.key === activeCategory);

  // 上一篇/下一篇逻辑
  const currentIndex = selectedNews 
    ? filteredNews.findIndex(item => item.link === selectedNews.link) 
    : -1;
  
  const prevNews = currentIndex > 0 ? filteredNews[currentIndex - 1] : null;
  const nextNews = currentIndex < filteredNews.length - 1 ? filteredNews[currentIndex + 1] : null;

  const handlePrevNext = (newsItem: NewsItem) => {
    setSelectedNews(newsItem);
    fetchNewsDetail(newsItem.link);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* 顶部条带 - 桂林学院校徽风格 */}
      <div className="bg-[#1E6B56] text-white py-2">
        <div className="container mx-auto px-4 flex justify-between items-center text-sm">
          <div className="flex items-center gap-4">
            <span>向学·向善·自律·自强</span>
          </div>
          <div className="flex items-center gap-4">
            <span>桂林学院</span>
          </div>
        </div>
      </div>

      {/* 主头部 - 桂林山水特色 */}
      <header className="bg-white shadow-md">
        <div className="container mx-auto px-4 py-6">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-4">
              {/* 桂林学院校徽 */}
              <div className="relative w-16 h-16 flex items-center justify-center">
                <img 
                  src="https://ts1.tc.mm.bing.net/th/id/OIP-C.r9l9DixAENuo0PyR-beucgHaHZ?rs=1&pid=ImgDetMain&o=7&rm=3" 
                  alt="桂林学院校徽" 
                  className="w-full h-full object-contain"
                />
              </div>
              <div>
                <h1 className="text-2xl md:text-3xl font-bold text-[#1E6B56] tracking-wide">
                  桂林学院新闻中心
                </h1>
                <p className="text-gray-500 text-sm mt-1">Guilin University News Center</p>
              </div>
            </div>

            {/* 搜索框 - 北风格 */}
            <div className="relative w-full md:w-96">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </div>
              <input
                type="text"
                placeholder="搜索新闻..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-lg
                         focus:outline-none focus:ring-2 focus:ring-[#1E6B56] focus:border-transparent
                         transition-all text-gray-700 placeholder-gray-400"
              />
            </div>
          </div>
        </div>

        {/* 导航条 - 桂林学院风格 */}
        <nav className="bg-[#1E6B56] text-white">
          <div className="container mx-auto px-4">
            <div className="flex overflow-x-auto">
              {CATEGORIES.map((category: CategoryInfo) => (
                <button
                  key={category.key}
                  onClick={() => setActiveCategory(category.key)}
                  className={`
                    px-6 py-3 font-medium whitespace-nowrap transition-all relative
                    ${activeCategory === category.key
                      ? 'bg-white text-[#1E6B56]'
                      : 'hover:bg-white/10'
                    }
                  `}
                >
                  <span className="mr-2">{category.icon}</span>
                  <span>{category.label}</span>
                </button>
              ))}
            </div>
          </div>
        </nav>
      </header>

      {/* 装饰条 - 桂林学院校徽风格 */}
      <div className="h-1 bg-gradient-to-r from-[#1E6B56] via-[#4A9D7C] to-[#1E6B56]"></div>

      {/* 主内容区 */}
      <main className="container mx-auto px-4 py-8">
        {/* 当前分类信息 */}
        <div className="mb-6 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-1 h-8 bg-[#1E6B56] rounded-full"></div>
            <div>
              <h2 className="text-xl font-bold text-gray-800">
                {currentCategoryInfo?.label}
              </h2>
              <p className="text-sm text-gray-500">
                {currentCategoryInfo?.description}
              </p>
            </div>
          </div>
          <span className="text-sm text-gray-400">
            共 {filteredNews.length} 条
          </span>
        </div>

        {/* 错误状态 */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-6 text-center mb-6">
            <p className="text-red-600 mb-2">⚠️ {error}</p>
            <button
              onClick={() => fetchNews(activeCategory)}
              className="text-[#0D9488] hover:text-[#0D9488]/80 underline"
            >
              点击重试
            </button>
          </div>
        )}

        {/* 加载状态 */}
        {loading && (
          <div className="grid gap-4">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className="bg-white rounded-lg p-6 shadow-sm border-l-4 border-[#1E6B56]">
                <div className="loading-shimmer h-6 w-3/4 rounded mb-3"></div>
                <div className="loading-shimmer h-4 w-1/4 rounded"></div>
              </div>
            ))}
          </div>
        )}

        {/* 新闻列表 - 北大风格网格 */}
        {!loading && !error && (
          <>
            {filteredNews.length === 0 ? (
              <div className="bg-white rounded-lg p-12 text-center shadow-sm">
                <div className="w-16 h-16 mx-auto mb-4 text-gray-300">
                  <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
                  </svg>
                </div>
                <p className="text-gray-500 text-lg">
                  {searchTerm ? '没有找到匹配的新闻' : '暂无新闻'}
                </p>
              </div>
            ) : (
              <div className="grid gap-4">
                {filteredNews.map((item: NewsItem, index: number) => (
                  <article
                    key={index}
                    onClick={() => {
                      setSelectedNews(item);
                      fetchNewsDetail(item.link);
                    }}
                    className="news-card bg-white rounded-lg shadow-sm hover:shadow-md
                             border-l-4 border-[#1E6B56] cursor-pointer group"
                  >
                    <div className="p-5">
                      <div className="flex items-start justify-between gap-4">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-2">
                            <span className="inline-block px-2 py-0.5 bg-[#E8F5F1] text-[#1E6B56] text-xs rounded">
                              {currentCategoryInfo?.label}
                            </span>
                            <span className="text-gray-400 text-sm">•</span>
                            <span className="text-gray-400 text-sm">{item.date}</span>
                          </div>
                          <h3 className="text-lg font-medium text-gray-800 group-hover:text-[#1E6B56]
                                       transition-colors line-clamp-2 leading-snug">
                            {item.title}
                          </h3>
                        </div>
                        <div className="flex items-center gap-2 text-[#1E6B56] opacity-0 group-hover:opacity-100
                                      transition-opacity flex-shrink-0">
                          <span className="text-sm">查看详情</span>
                          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                          </svg>
                        </div>
                      </div>
                    </div>
                  </article>
                ))}
              </div>
            )}
          </>
        )}
      </main>

      {/* 页脚 */}
      <footer className="bg-gray-800 text-white py-8 mt-12">
        <div className="container mx-auto px-4">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-full overflow-hidden bg-gray-700">
                <img 
                  src="https://ts1.tc.mm.bing.net/th/id/OIP-C.r9l9DixAENuo0PyR-beucgHaHZ?rs=1&pid=ImgDetMain&o=7&rm=3" 
                  alt="桂林学院校徽" 
                  className="w-full h-full object-cover rounded-full"
                />
              </div>
              <div>
                <p className="text-lg font-bold">桂林学院新闻中心</p>
                <p className="text-sm text-gray-400">向学·向善·自律·自强</p>
              </div>
            </div>
            <div className="text-center md:text-right">
              <p className="text-sm text-gray-400">
                © 2026 桂林学院 版权所有
              </p>
              <p className="text-xs text-gray-500 mt-1">
                桂林山水甲天下 · 校园文化润人心
              </p>
            </div>
          </div>
        </div>
      </footer>

      {/* 详情弹窗 - 北大风格 */}
      {selectedNews && (
        <div
          className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4"
          onClick={closeDetail}
        >
          <div
            className="bg-white rounded-lg max-w-3xl w-full max-h-[85vh] overflow-hidden shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            {/* 弹窗头部 */}
            <div className="bg-[#1E6B56] px-6 py-4 text-white">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <span className="text-sm text-white/70">{currentCategoryInfo?.label}</span>
                  <h2 className="text-lg font-bold mt-1">{selectedNews.title}</h2>
                </div>
                <button
                  onClick={closeDetail}
                  className="text-white/70 hover:text-white text-2xl leading-none"
                >
                  ×
                </button>
              </div>
              <p className="text-sm text-white/60 mt-2">📅 {selectedNews.date}</p>
            </div>

            {/* 装饰条 */}
            <div className="h-1 bg-gradient-to-r from-[#1E6B56] via-[#4A9D7C] to-[#1E6B56]"></div>

            {/* 内容区 */}
            <div className="p-6 overflow-y-auto max-h-[55vh]">
              {detailLoading && (
                <div className="space-y-4">
                  <div className="loading-shimmer h-4 w-full rounded"></div>
                  <div className="loading-shimmer h-4 w-5/6 rounded"></div>
                  <div className="loading-shimmer h-4 w-4/6 rounded"></div>
                  <div className="loading-shimmer h-4 w-full rounded"></div>
                  <div className="loading-shimmer h-4 w-3/4 rounded"></div>
                </div>
              )}

              {!detailLoading && newsDetail && (
                <div
                  className="news-detail-content text-sm leading-relaxed"
                  dangerouslySetInnerHTML={{ __html: newsDetail.content }}
                />
              )}

              {!detailLoading && !newsDetail && (
                <div className="bg-gray-50 rounded-lg p-4 text-center">
                  <p className="text-gray-500">⚠️ 获取详情失败，请点击下方链接访问原文</p>
                </div>
              )}
            </div>

            {/* 上一篇/下一篇导航 */}
            <div className="border-t border-gray-200 bg-white">
              <div className="px-6 py-3 bg-[#1E6B56]/5">
                <span className="text-sm font-medium text-[#1E6B56]">文章导航</span>
              </div>
              
              <div className="px-6 py-3 space-y-2">
                {/* 上一篇 */}
                <div className="flex items-center gap-3">
                  <div className="flex-shrink-0 w-8 h-8 rounded-full bg-[#1E6B56]/10 flex items-center justify-center">
                    <svg className="w-4 h-4 text-[#1E6B56]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                    </svg>
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="text-xs text-gray-500 block">上一篇</span>
                    {prevNews ? (
                      <button
                        onClick={() => handlePrevNext(prevNews)}
                        className="text-sm text-[#1E6B56] hover:text-[#1E6B56]/80 truncate block group"
                      >
                        <span className="group-hover:underline">{prevNews.title}</span>
                      </button>
                    ) : (
                      <span className="text-sm text-gray-400 truncate">暂无上一篇</span>
                    )}
                  </div>
                </div>
                
                {/* 分隔线 */}
                <div className="h-px bg-gray-100 mx-11"></div>
                
                {/* 下一篇 */}
                <div className="flex items-center gap-3">
                  <div className="flex-shrink-0 w-8 h-8 rounded-full bg-[#1E6B56]/10 flex items-center justify-center">
                    <svg className="w-4 h-4 text-[#1E6B56]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                    </svg>
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="text-xs text-gray-500 block">下一篇</span>
                    {nextNews ? (
                      <button
                        onClick={() => handlePrevNext(nextNews)}
                        className="text-sm text-[#1E6B56] hover:text-[#1E6B56]/80 truncate block group"
                      >
                        <span className="group-hover:underline">{nextNews.title}</span>
                      </button>
                    ) : (
                      <span className="text-sm text-gray-400 truncate">暂无下一篇</span>
                    )}
                  </div>
                </div>
              </div>
              
              {/* 操作按钮 */}
              <div className="px-6 py-4 bg-gray-50 border-t flex justify-between items-center">
                <a
                  href={selectedNews.link}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-[#1E6B56] hover:text-[#1E6B56]/80 flex items-center gap-1.5 text-sm"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                  <span>访问原文</span>
                </a>
                <button
                  onClick={closeDetail}
                  className="px-6 py-2 bg-[#1E6B56] text-white rounded-lg hover:bg-[#155545]
                           transition-colors text-sm font-medium shadow-sm"
                >
                  关闭
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;