import React from 'react';
import { Github, Youtube } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface SocialLinkProps {
  platform: 'github' | 'youtube';
  className?: string;
}

export const SocialLinks: React.FC = () => {
  return (
    <div className="flex gap-2">
      <a href="https://github.com/lornu-ai" aria-label="Lornu AI GitHub" target="_blank" rel="noopener noreferrer">
        <Button variant="ghost" size="icon">
          <Github className="h-6 w-6" />
        </Button>
      </a>
      <a href="https://www.youtube.com/@lornu-ai" aria-label="Lornu AI YouTube" target="_blank" rel="noopener noreferrer">
        <Button variant="ghost" size="icon">
          <Youtube className="h-6 w-6" />
        </Button>
      </a>
    </div>
  );
};

export default SocialLinks;
