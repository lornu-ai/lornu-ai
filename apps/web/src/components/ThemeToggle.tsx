import React from 'react';
import { useTheme } from '@/contexts/ThemeContext';
import { Button } from '@/components/ui/button';
import { Sun, Moon, Terminal } from '@phosphor-icons/react';

const ThemeToggle: React.FC = () => {
  const { theme, setTheme } = useTheme();

  const toggleTheme = () => {
    if (theme === 'light') {
      setTheme('dark');
    } else if (theme === 'dark') {
      setTheme('open-source-pro');
    } else {
      setTheme('light');
    }
  };

  const renderIcon = () => {
    if (theme === 'light') {
      return <Sun size={24} />;
    } else if (theme === 'dark') {
      return <Moon size={24} />;
    } else {
      return <Terminal size={24} />;
    }
  };

  return (
    <Button onClick={toggleTheme} variant="ghost" size="icon" aria-label="Toggle theme">
      {renderIcon()}
    </Button>
  );
};

export default ThemeToggle;