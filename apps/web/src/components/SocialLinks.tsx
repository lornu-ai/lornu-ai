import React from 'react';
import { Github, Youtube } from 'lucide-react';
import { Button } from '@/components/ui/button';

export const SocialLinks: React.FC = () => {
  return (
    <div className="flex gap-2">
      <Button asChild variant="ghost" size="icon">
        <a href="https://github.com/lornu-ai" aria-label="Lornu AI GitHub" target="_blank" rel="noopener noreferrer">
          <Github className="h-6 w-6" />
        </a>
      </Button>
      <Button asChild variant="ghost" size="icon">
        <a href="https://www.youtube.com/@lornu-ai" aria-label="Lornu AI YouTube" target="_blank" rel="noopener noreferrer">
          <Youtube className="h-6 w-6" />
        </a>
      </Button>
    </div>
  );
};

export default SocialLinks;