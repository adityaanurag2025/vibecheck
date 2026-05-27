export const metadata = {
  title: "Demo App",
  description: "Deliberately broken Next.js app for vibecheck testing",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
