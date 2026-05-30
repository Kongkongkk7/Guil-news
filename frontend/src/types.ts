export interface NewsItem {
  title: string;
  link: string;
  date: string;
}

export interface NewsResponse {
  success: boolean;
  data: NewsItem[];
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
    label: '学校新闻',
    icon: '🏛️',
    description: '学校重要新闻和公告'
  },
  {
    key: 'xsdt',
    label: '学生动态',
    icon: '🎓',
    description: '学生学习生活动态'
  },
  {
    key: 'gyrw',
    label: '校友人物',
    icon: '👥',
    description: '杰出校友风采展示'
  },
  {
    key: 'mtgy',
    label: '媒体校园',
    icon: '📰',
    description: '媒体眼中的桂林理工'
  }
];