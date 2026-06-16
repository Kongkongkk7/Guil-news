export interface NewsItem {
  title: string;
  link: string;
  date: string;
  thumbnail?: string;
}

export interface NewsResponse {
  success: boolean;
  data: NewsItem[];
}

export interface NewsDetailResponse {
  success: boolean;
  data: {
    title: string;
    content: string;
    url: string;
    thumbnail?: string;
  };
}

export type NewsCategory = 'xxxw' | 'xsdt' | 'gyrw' | 'mtgy';

export interface CategoryInfo {
  key: NewsCategory;
  label: string;
  icon: string;
  description: string;
}

export const CATEGORIES: CategoryInfo[] = [
  {
    key: 'xxxw',
    label: '桂院要闻',
    icon: '📋',
    description: '学校重要新闻和公告'
  },
  {
    key: 'xsdt',
    label: '学术动态',
    icon: '📚',
    description: '学术讲座与科研动态'
  },
  {
    key: 'gyrw',
    label: '校园要闻',
    icon: '📢',
    description: '校园新鲜事和活动'
  },
  {
    key: 'mtgy',
    label: '媒体关注',
    icon: '📰',
    description: '媒体对学校的报道和关注'
  }
];
