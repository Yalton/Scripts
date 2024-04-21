import React, { useRef, useEffect } from 'react';

const ImageScatterAnimation = ({ image, width, height }) => {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');

    const img = new Image();
    img.src = image;
    img.onload = () => {
      ctx.drawImage(img, 0, 0, width, height);
      const imageData = ctx.getImageData(0, 0, width, height);
      const particles = [];

      // Create particles from image pixels
      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const index = (y * width + x) * 4;
          const r = imageData.data[index];
          const g = imageData.data[index + 1];
          const b = imageData.data[index + 2];
          const a = imageData.data[index + 3];

          particles.push({
            x: x,
            y: y,
            color: `rgba(${r}, ${g}, ${b}, ${a})`,
            originalX: x,
            originalY: y,
          });
        }
      }

      // Scatter particles randomly
      particles.forEach((particle) => {
        particle.x = Math.random() * width;
        particle.y = Math.random() * height;
      });

      // Animation loop
      const animate = () => {
        ctx.clearRect(0, 0, width, height);

        particles.forEach((particle) => {
          ctx.fillStyle = particle.color;
          ctx.fillRect(particle.x, particle.y, 1, 1);

          // Move particles back to original positions semi-randomly
          const dx = particle.originalX - particle.x;
          const dy = particle.originalY - particle.y;
          const distance = Math.sqrt(dx * dx + dy * dy);

          if (distance > 0) {
            const speed = Math.random() * 5 + 1;
            const angle = Math.atan2(dy, dx);
            particle.x += Math.cos(angle) * speed;
            particle.y += Math.sin(angle) * speed;
          }
        });

        requestAnimationFrame(animate);
      };

      animate();
    };
  }, [image, width, height]);

  return <canvas ref={canvasRef} width={width} height={height} />;
};

export default ImageScatterAnimation;