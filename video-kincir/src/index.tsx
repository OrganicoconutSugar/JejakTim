import React from 'react';
import {AbsoluteFill, Composition, Img, registerRoot, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';

type WindmillProps = {background: string; secondsPerTurn: number};

export const Windmill: React.FC<WindmillProps> = ({background, secondsPerTurn}) => {
  const frame = useCurrentFrame();
  const {fps, width, height} = useVideoConfig();
  // The uploaded PNG is 1100 square, but its yellow hub is off-center.
  // Rotate around the actual hub, never around the image bounding box.
  const scale = 0.82;
  const pivotX = 619 * scale;
  const pivotY = 648.5 * scale;
  const rotation = (frame / fps / secondsPerTurn) * 360;
  return (
    <AbsoluteFill style={{backgroundColor: background, overflow: 'hidden'}}>
      <Img src={staticFile('kincir.png')} style={{
        position: 'absolute', width: 1100 * scale, height: 1100 * scale,
        left: width / 2 - pivotX, top: height / 2 - pivotY,
        transformOrigin: `${pivotX}px ${pivotY}px`,
        transform: `rotate(${rotation}deg)`,
      }} />
    </AbsoluteFill>
  );
};

const Root: React.FC = () => <>
  <Composition id="KincirPortrait" component={Windmill} width={1080} height={1920}
    fps={60} durationInFrames={480} defaultProps={{background: '#FFFFFF', secondsPerTurn: 2}} />
  <Composition id="KincirTransparent" component={Windmill} width={1080} height={1920}
    fps={60} durationInFrames={480} defaultProps={{background: 'transparent', secondsPerTurn: 2}} />
</>;

registerRoot(Root);
