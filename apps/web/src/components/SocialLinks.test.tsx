/**
 * @vitest-environment jsdom
 */
import React from 'react';
import { render, screen } from '@testing-library/react';
import SocialLinks from './SocialLinks';

describe('SocialLinks', () => {
  it('should render links to GitHub and YouTube', () => {
    render(<SocialLinks />);

    const githubLink = screen.getByLabelText('Lornu AI GitHub');
    expect(githubLink).toBeInTheDocument();
    expect(githubLink).toHaveAttribute('href', 'https://github.com/lornu-ai');

    const youtubeLink = screen.getByLabelText('Lornu AI YouTube');
    expect(youtubeLink).toBeInTheDocument();
    expect(youtubeLink).toHaveAttribute('href', 'https://www.youtube.com/@lornu-ai');
  });
});