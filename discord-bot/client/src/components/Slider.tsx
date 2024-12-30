import { ChangeEvent, FC, useEffect, useState } from "react";
import "./Slider.scss";

interface SliderProps {
  min: number;
  max: number;
  current: number;
  onChange: (value: number) => void;
}
export const Slider: FC<SliderProps> = ({ min, max, current, onChange }) => {
  const [localValue, setLocalValue] = useState<number>(current);
  const [isDragging, setIsDragging] = useState<boolean>(false);

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    setLocalValue(Number(e.target.value));
  };

  const handleMouseDown = () => {
    setIsDragging(true);
  };

  const handleMouseUp = () => {
    setIsDragging(false);
    onChange(localValue);
  };
  useEffect(() => {
    if (!isDragging) setLocalValue(current);
  }, [current, isDragging]);

  return (
    <div className="w-100">
      <input
        type="range"
        min={min}
        max={max}
        value={localValue}
        onChange={handleChange}
        onMouseDown={handleMouseDown}
        onMouseUp={handleMouseUp}
        className="slider w-100"
      />
    </div>
  );
};
