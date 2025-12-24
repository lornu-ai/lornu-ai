/**
 * @vitest-environment jsdom
 */
import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';
import { ThemeProvider, useTheme } from '../contexts/ThemeContext';
import ThemeToggle from './ThemeToggle';

const TestComponent = () => {
  const { theme } = useTheme();
  return <div>Current theme: {theme}</div>;
};

describe('ThemeToggle', () => {
  it('should toggle theme on click', () => {
    render(
      <ThemeProvider>
        <ThemeToggle />
        <TestComponent />
      </ThemeProvider>
    );

    const toggleButton = screen.getByRole('button');

    // Initial theme is system
    expect(screen.getByText('Current theme: system')).toBeInTheDocument();

    // Click to change to light
    fireEvent.click(toggleButton);
    expect(screen.getByText('Current theme: light')).toBeInTheDocument();

    // Click to change to dark
    fireEvent.click(toggleButton);
    expect(screen.getByText('Current theme: dark')).toBeInTheDocument();

    // Click to change to open-source-pro
    fireEvent.click(toggleButton);
    expect(screen.getByText('Current theme: open-source-pro')).toBeInTheDocument();

    // Click to change back to system
    fireEvent.click(toggleButton);
    expect(screen.getByText('Current theme: system')).toBeInTheDocument();
  });
});
