import React from 'react';
import { useTheme, Theme } from '@/contexts/ThemeContext';
import { Button } from '@/components/ui/button';
import { Sun, Moon, Terminal } from '@phosphor-icons/react';
import { Monitor } from 'lucide-react';

const themes: Theme[] = ['system', 'light', 'dark', 'open-source-pro'];

const ThemeToggle: React.FC = () => {
  const { theme, setTheme } = useTheme();

  const toggleTheme = () => {
    const currentIndex = themes.indexOf(theme);
    const nextIndex = (currentIndex + 1) % themes.length;
    setTheme(themes[nextIndex]);
  };

  const nextTheme = themes[(themes.indexOf(theme) + 1) % themes.length];

  const renderIcon = () => {
    if (theme === 'system') {
      return <Monitor className="h-5 w-5" />;
    }
    if (theme === 'light') {
      return <Sun size={24} />;
    }
    if (theme === 'dark') {
      return <Moon size={24} />;
    }
    return <Terminal size={24} />;
  };

  return (
    <Button
      onClick={toggleTheme}
      variant="ghost"
      size="icon"
      aria-label="Toggle theme"
      title={`Switch to ${nextTheme} theme`}
    >
      {renderIcon()}
    </Button>
  );
};

export default ThemeToggle;
