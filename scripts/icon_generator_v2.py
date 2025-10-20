#!/usr/bin/env python3
"""
🎨 Configurable Icon Generator - JSON-Driven Edition
Advanced AI-powered icon generation with flexible JSON configuration
"""

import os
import json
import asyncio
import logging
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any, Union
from dataclasses import dataclass, asdict
import jsonschema
import re

# Third-party imports
from google import genai
from google.genai import types
from PIL import Image
from io import BytesIO
from dotenv import load_dotenv
import base64
from rembg import remove

# Load environment variables from scripts directory
load_dotenv(dotenv_path='.env')

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('icon_generation.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class IconConfig:
    """Data class for individual icon configuration"""
    name: str
    display_name: str
    description: str
    category: str
    keywords: List[str]
    style_overrides: Optional[Dict[str, Any]] = None

@dataclass
class GenerationConfig:
    """Data class for generation settings"""
    style: Dict[str, Any]
    output: Dict[str, Any]
    prompts: Dict[str, Any]
    ai_settings: Dict[str, Any]

@dataclass
class ProjectConfig:
    """Data class for project metadata"""
    name: str
    type: str
    description: str
    target_platforms: List[str]
    brand_colors: List[str]

@dataclass
class IconResult:
    """Result of PNG icon generation"""
    name: str
    metadata: Dict[str, Any]
    generation_time: float
    success: bool = True
    error: Optional[str] = None

class ConfigLoader:
    """Handles loading and validation of JSON configuration files"""
    
    def __init__(self, schema_path: str = "icon-config.schema.json"):
        self.schema_path = schema_path
        self.schema = self._load_schema()
    
    def _load_schema(self) -> Dict[str, Any]:
        """Load JSON schema for validation"""
        try:
            with open(self.schema_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            logger.warning(f"Schema file {self.schema_path} not found. Skipping validation.")
            return {}
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in schema file: {e}")
            return {}
    
    def load_config(self, config_path: str) -> Dict[str, Any]:
        """Load and validate configuration from JSON file"""
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
            
            # Validate against schema if available
            if self.schema:
                try:
                    jsonschema.validate(config, self.schema)
                    logger.info("Configuration validation passed")
                except jsonschema.ValidationError as e:
                    logger.error(f"Configuration validation failed: {e.message}")
                    raise ValueError(f"Invalid configuration: {e.message}")
            
            return config
        
        except FileNotFoundError:
            raise FileNotFoundError(f"Configuration file {config_path} not found")
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in configuration file: {e}")
    
    def parse_config(self, config_data: Dict[str, Any]) -> tuple[ProjectConfig, List[IconConfig], GenerationConfig]:
        """Parse configuration data into structured objects"""
        
        # Parse project config
        project_data = config_data.get('project', {})
        project_config = ProjectConfig(
            name=project_data.get('name', 'Untitled Project'),
            type=project_data.get('type', 'other'),
            description=project_data.get('description', ''),
            target_platforms=project_data.get('target_platforms', []),
            brand_colors=project_data.get('brand_colors', [])
        )
        
        # Parse icon configs
        icons_data = config_data.get('icons', [])
        icon_configs = []
        for icon_data in icons_data:
            icon_config = IconConfig(
                name=icon_data.get('name', ''),
                display_name=icon_data.get('display_name', icon_data.get('name', '')),
                description=icon_data.get('description', ''),
                category=icon_data.get('category', 'other'),
                keywords=icon_data.get('keywords', []),
                style_overrides=icon_data.get('style_overrides')
            )
            icon_configs.append(icon_config)
        
        # Parse generation config
        generation_data = config_data.get('generation', {})
        generation_config = GenerationConfig(
            style=generation_data.get('style', {}),
            output=generation_data.get('output', {}),
            prompts=generation_data.get('prompts', {}),
            ai_settings=generation_data.get('ai_settings', {})
        )
        
        return project_config, icon_configs, generation_config

class PromptTemplate:
    """Handles prompt template processing with placeholders"""
    
    @staticmethod
    def process_template(template: str, **kwargs) -> str:
        """Process template string with placeholder replacement"""
        try:
            # Replace placeholders in the format {placeholder}
            processed = template
            for key, value in kwargs.items():
                placeholder = f"{{{key}}}"
                if isinstance(value, list):
                    value = ", ".join(str(v) for v in value)
                processed = processed.replace(placeholder, str(value))
            
            return processed
        except Exception as e:
            logger.error(f"Error processing template: {e}")
            return template

class ConfigurableIconGenerator:
    """Main icon generator class that uses JSON configuration"""
    
    def __init__(self, config_path: str):
        self.config_loader = ConfigLoader()
        self.config_data = self.config_loader.load_config(config_path)
        self.project_config, self.icon_configs, self.generation_config = self.config_loader.parse_config(self.config_data)
        
        # Initialize AI clients
        self._setup_ai_clients()
        
        # Setup output directory
        self._setup_output_directory()
        
        logger.info(f"Initialized generator for project: {self.project_config.name}")
        logger.info(f"Loaded {len(self.icon_configs)} icon configurations")
    
    def _setup_ai_clients(self):
        """Setup AI clients with API keys"""
        api_key = os.getenv('GOOGLE_API_KEY')
        if not api_key:
            raise ValueError("GOOGLE_API_KEY environment variable is required")
        
        # Configure Gemini client
        self.client = genai.Client(api_key=api_key)
        
        # Set default model for image generation
        self.image_model = self.generation_config.ai_settings.get('image_model', 'gemini-2.5-flash-image-preview')
        
        logger.info(f"Initialized Gemini client with model: {self.image_model}")
    
    def _setup_output_directory(self):
        """Setup output directory from configuration"""
        output_dir = self.generation_config.output.get('directory', './generated-icons')
        self.output_path = Path(output_dir)
        self.output_path.mkdir(parents=True, exist_ok=True)
        logger.info(f"Output directory: {self.output_path}")
    
    def _remove_background_with_rembg(self, image_data: bytes) -> bytes:
        """Remove background using rembg library"""
        try:
            logger.info("🎨 Removing background with rembg...")
            start_time = time.time()
            
            # Apply rembg to remove background
            processed_data = remove(image_data)
            
            processing_time = time.time() - start_time
            logger.info(f"✅ Background removed successfully in {processing_time:.2f}s")
            
            return processed_data
            
        except Exception as e:
            logger.error(f"❌ Failed to remove background with rembg: {e}")
            # Return original data if rembg fails
            return image_data
    
    def _crop_to_content(self, image_data: bytes) -> bytes:
        """Crop image to content with configurable aspect ratio and smart padding"""
        # Get crop config from generation config
        crop_config = self.generation_config.output.get('crop', {})
        
        # Default values
        enabled = crop_config.get('enabled', True)
        aspect_ratio = crop_config.get('aspect_ratio', 'square')
        padding_percentage = crop_config.get('padding_percentage', 15) / 100.0
        min_padding = crop_config.get('min_padding_px', 10)
        
        if not enabled:
            logger.info("🚫 Cropping disabled in config")
            return image_data
        
        try:
            logger.info(f"✂️ Cropping to content with {aspect_ratio} aspect ratio...")
            start_time = time.time()
            
            # Load image
            image = Image.open(BytesIO(image_data))
            
            # Convert to RGBA if not already
            if image.mode != 'RGBA':
                image = image.convert('RGBA')
            
            # Get the bounding box of non-transparent pixels
            bbox = image.getbbox()
            
            if bbox:
                left, top, right, bottom = bbox
                content_width = right - left
                content_height = bottom - top
                
                # Calculate padding
                padding_x = max(min_padding, int(content_width * padding_percentage))
                padding_y = max(min_padding, int(content_height * padding_percentage))
                
                # Add padding to content bounds
                padded_left = max(0, left - padding_x)
                padded_top = max(0, top - padding_y)
                padded_right = min(image.width, right + padding_x)
                padded_bottom = min(image.height, bottom + padding_y)
                
                # Calculate dimensions with padding
                padded_width = padded_right - padded_left
                padded_height = padded_bottom - padded_top
                
                # Apply aspect ratio
                if aspect_ratio == 'square':
                    # Make it square by using the larger dimension
                    final_size = max(padded_width, padded_height)
                    final_width = final_height = final_size
                elif aspect_ratio == 'original':
                    # Keep original proportions
                    final_width = padded_width
                    final_height = padded_height
                else:
                    # For future: support custom ratios like "16:9", "4:3", etc.
                    final_width = padded_width
                    final_height = padded_height
                
                # Calculate center point
                center_x = (padded_left + padded_right) // 2
                center_y = (padded_top + padded_bottom) // 2
                
                # Calculate crop bounds centered on content
                half_width = final_width // 2
                half_height = final_height // 2
                crop_left = max(0, center_x - half_width)
                crop_top = max(0, center_y - half_height)
                crop_right = min(image.width, crop_left + final_width)
                crop_bottom = min(image.height, crop_top + final_height)
                
                # Adjust if we hit image boundaries
                if crop_right - crop_left < final_width:
                    crop_left = max(0, crop_right - final_width)
                if crop_bottom - crop_top < final_height:
                    crop_top = max(0, crop_bottom - final_height)
                
                # Crop the image
                cropped_image = image.crop((crop_left, crop_top, crop_right, crop_bottom))
                
                # If the cropped image is smaller than target size (due to image boundaries),
                # create a new image and paste the cropped content in the center
                if cropped_image.size != (final_width, final_height):
                    target_image = Image.new('RGBA', (final_width, final_height), (0, 0, 0, 0))
                    paste_x = (final_width - cropped_image.width) // 2
                    paste_y = (final_height - cropped_image.height) // 2
                    target_image.paste(cropped_image, (paste_x, paste_y))
                    cropped_image = target_image
                
                # Save to bytes
                output = BytesIO()
                cropped_image.save(output, format='PNG')
                cropped_data = output.getvalue()
                
                processing_time = time.time() - start_time
                logger.info(f"✅ Cropped to {aspect_ratio} content in {processing_time:.2f}s")
                logger.info(f"   • Original content: {content_width}x{content_height}")
                logger.info(f"   • Final size: {cropped_image.size}")
                logger.info(f"   • Padding: {padding_percentage*100:.0f}% ({padding_x}px x {padding_y}px)")
                
                return cropped_data
            else:
                logger.warning("⚠️ No content found to crop, returning original")
                return image_data
                
        except Exception as e:
            logger.error(f"❌ Failed to crop image: {e}")
            return image_data
    
    def _resize_to_standard_sizes(self, image_data: bytes, icon_name: str) -> Dict[str, bytes]:
        """Resize icon to standard Android sizes"""
        try:
            logger.info("📐 Resizing to standard Android sizes...")
            start_time = time.time()
            
            # Standard Android icon sizes
            android_sizes = {
                'mdpi': 48,      # 1x
                'hdpi': 72,      # 1.5x
                'xhdpi': 96,     # 2x
                'xxhdpi': 144,   # 3x
                'xxxhdpi': 192   # 4x
            }
            
            # Load image
            image = Image.open(BytesIO(image_data))
            
            # Convert to RGBA if not already
            if image.mode != 'RGBA':
                image = image.convert('RGBA')
            
            resized_images = {}
            
            for density, size in android_sizes.items():
                # Resize with high quality
                resized = image.resize((size, size), Image.Resampling.LANCZOS)
                
                # Save to bytes
                output = BytesIO()
                resized.save(output, format='PNG')
                resized_images[density] = output.getvalue()
                
                logger.info(f"   • {density}: {size}x{size}px")
            
            processing_time = time.time() - start_time
            logger.info(f"✅ Resized to {len(android_sizes)} standard sizes in {processing_time:.2f}s")
            
            return resized_images
            
        except Exception as e:
            logger.error(f"❌ Failed to resize image: {e}")
            return {}
    
    def _analyze_transparency_quality(self, image_data: bytes, icon_name: str):
        """Analyze transparency quality of processed image"""
        try:
            # Load image from bytes
            image = Image.open(BytesIO(image_data))
            
            # Check if image has transparency
            if image.mode in ('RGBA', 'LA') or 'transparency' in image.info:
                # Count transparent pixels
                if image.mode == 'RGBA':
                    alpha_channel = image.split()[-1]
                    transparent_pixels = sum(1 for pixel in alpha_channel.getdata() if pixel < 128)
                    total_pixels = image.width * image.height
                    transparency_percentage = (transparent_pixels / total_pixels) * 100
                    
                    logger.info(f"📊 Icon '{icon_name}' transparency analysis:")
                    logger.info(f"   • Transparent pixels: {transparent_pixels:,} ({transparency_percentage:.1f}%)")
                    logger.info(f"   • Image size: {image.width}x{image.height}")
                    logger.info(f"   • Supports transparency: ✅")
                    
                    if transparency_percentage > 50:
                        logger.info(f"   • Quality: 🎯 Excellent background removal!")
                    elif transparency_percentage > 20:
                        logger.info(f"   • Quality: ✅ Good background removal")
                    else:
                        logger.info(f"   • Quality: ⚠️ Limited background removal")
                else:
                    logger.info(f"📊 Icon '{icon_name}' has transparency support but not RGBA mode")
            else:
                logger.info(f"📊 Icon '{icon_name}' does not support transparency")
                
        except Exception as e:
            logger.error(f"❌ Failed to analyze transparency for {icon_name}: {e}")
    
    def _create_generation_prompt(self, icon_config: IconConfig) -> str:
        """Create generation prompt from template and icon config"""
        
        # Get base template
        base_template = self.generation_config.prompts.get('base_template', 
            "Create a {complexity} {fill_style} icon for {description}. Style: {design_system} design with {color_scheme} colors.")
        
        # Merge default style with icon-specific overrides
        style = self.generation_config.style.copy()
        if icon_config.style_overrides:
            style.update(icon_config.style_overrides)
        
        # Prepare template variables
        template_vars = {
            'name': icon_config.name,
            'display_name': icon_config.display_name,
            'description': icon_config.description,
            'category': icon_config.category,
            'keywords': icon_config.keywords,
            'project_type': self.project_config.type,
            'target_platforms': self.project_config.target_platforms,
            'brand_colors': self.project_config.brand_colors,
            **style  # Unpack all style settings
        }
        
        # Process base template
        prompt = PromptTemplate.process_template(base_template, **template_vars)
        
        # Add style additions
        style_additions = self.generation_config.prompts.get('style_additions', [])
        if style_additions:
            prompt += "\n\nAdditional requirements:\n" + "\n".join(f"- {addition}" for addition in style_additions)
        
        # Add negative prompts
        negative_prompts = self.generation_config.prompts.get('negative_prompts', [])
        if negative_prompts:
            prompt += "\n\nAvoid:\n" + "\n".join(f"- {negative}" for negative in negative_prompts)
        
        # Add custom prompt if specified in icon config
        if icon_config.style_overrides and 'custom_prompt' in icon_config.style_overrides:
            prompt += f"\n\nCustom requirements: {icon_config.style_overrides['custom_prompt']}"
        
        # Add basic format requirements (rembg will handle background removal)
        prompt += "\n\nFORMAT REQUIREMENTS:"
        prompt += "\n- Generate as high-quality PNG image"
        prompt += "\n- Focus on clean, well-defined icon elements"
        prompt += "\n- Ensure good contrast and clarity for the icon design"
        
        return prompt
    
    async def generate_single_icon(self, icon_config: IconConfig) -> IconResult:
        """Generate a single icon using Gemini image generation API"""
        start_time = time.time()
        
        try:
            # Create generation prompt for image generation
            prompt = self._create_generation_prompt(icon_config)
            logger.info(f"Generating icon: {icon_config.name}")
            logger.debug(f"Prompt: {prompt}")
            
            # Generate image using Gemini generate_content API
            response = await asyncio.to_thread(
                self.client.models.generate_content,
                model=self.image_model,
                contents=[prompt]
            )
            
            # Parse response to get image data
            image_data = None
            for part in response.candidates[0].content.parts:
                if part.inline_data is not None:
                    image_data = part.inline_data.data
                    break
            
            if image_data is None:
                raise ValueError("No image data found in response")
            
            # Calculate generation time
            generation_time = time.time() - start_time
            
            # Create result with PNG data only
            result = IconResult(
                name=icon_config.name,
                metadata={
                    'display_name': icon_config.display_name,
                    'description': icon_config.description,
                    'category': icon_config.category,
                    'keywords': icon_config.keywords,
                    'style': self.generation_config.style,
                    'generation_time': generation_time,
                    'model_used': self.image_model,
                    'prompt': prompt,
                    'format': 'PNG',
                    'generation_method': 'gemini_generate_content_api',
                    'timestamp': datetime.now().isoformat(),
                    'image_data': image_data  # Store PNG data for saving
                },
                generation_time=generation_time
            )
            
            # Save icon
            await self._save_icon(result)
            
            logger.info(f"Successfully generated PNG icon: {icon_config.name} ({generation_time:.2f}s)")
            return result
            
        except Exception as e:
            generation_time = time.time() - start_time
            error_msg = f"Failed to generate icon {icon_config.name}: {str(e)}"
            logger.error(error_msg)
            
            return IconResult(
                name=icon_config.name,
                metadata={
                    'display_name': icon_config.display_name,
                    'description': icon_config.description,
                    'category': icon_config.category,
                    'keywords': icon_config.keywords,
                    'error': error_msg,
                    'generation_method': 'gemini_generate_content_api'
                },
                generation_time=generation_time,
                success=False,
                error=error_msg
            )
    

    
    async def _save_icon(self, result: IconResult):
        """Save generated PNG icon to file (NO SVG)"""
        try:
            # Get filename pattern
            filename_pattern = self.generation_config.output.get('filename_pattern', '{name}')
            filename = PromptTemplate.process_template(filename_pattern, 
                                                     name=result.name, 
                                                     timestamp=datetime.now().strftime('%Y%m%d_%H%M%S'))
            
            # Save PNG file ONLY
            png_path = self.output_path / f"{filename}.png"
            
            # Save PNG file if image data exists
            if 'image_data' in result.metadata and result.metadata['image_data']:
                image_data = result.metadata['image_data']
                logger.info(f"Saving PNG file: {png_path}")
                logger.debug(f"Image data type: {type(image_data)}")
                
                # Image data should be bytes from Gemini API
                if isinstance(image_data, bytes):
                    # Apply rembg to remove background
                    processed_image_data = self._remove_background_with_rembg(image_data)
                    
                    # Apply crop to remove empty space around content
                    cropped_image_data = self._crop_to_content(processed_image_data)
                    
                    # Save original image (with _original suffix)
                    original_path = self.output_path / f"{filename}_original.png"
                    with open(original_path, 'wb') as f:
                        f.write(image_data)
                    logger.info(f"✅ Original PNG saved: {original_path}")
                    
                    # Save processed image (main file)
                    with open(png_path, 'wb') as f:
                        f.write(cropped_image_data)
                    logger.info(f"✅ Processed PNG saved: {png_path}")
                    
                    # Analyze transparency quality
                    self._analyze_transparency_quality(cropped_image_data, result.name)
                    
                else:
                    logger.error(f"❌ Invalid image data type: {type(image_data)}")
                    raise ValueError(f"Expected bytes, got {type(image_data)}")
            else:
                logger.error("❌ No image data found in result metadata")
                raise ValueError("No image data to save")
            
            # Save metadata (exclude image_data to avoid JSON serialization error)
            metadata_path = self.output_path / f"{filename}.json"
            metadata_for_json = {k: v for k, v in result.metadata.items() if k != 'image_data'}
            with open(metadata_path, 'w', encoding='utf-8') as f:
                json.dump(metadata_for_json, f, indent=2)
            
            logger.info(f"Saved icon: {png_path}")
            
        except Exception as e:
            logger.error(f"Failed to save icon {result.name}: {e}")
    
    async def generate_all_icons(self) -> List[IconResult]:
        """Generate all icons from configuration"""
        logger.info(f"Starting generation of {len(self.icon_configs)} icons")
        
        results = []
        for icon_config in self.icon_configs:
            result = await self.generate_single_icon(icon_config)
            results.append(result)
            
            # Add delay between generations to avoid rate limiting
            await asyncio.sleep(1)
        
        # Generate summary report
        self._generate_summary_report(results)
        
        return results
    
    def _generate_summary_report(self, results: List[IconResult]):
        """Generate summary report of generation session"""
        successful = [r for r in results if r.success]
        failed = [r for r in results if not r.success]
        
        total_time = sum(r.generation_time for r in results)
        avg_time = total_time / len(results) if results else 0
        
        report = {
            'project': self.project_config.name,
            'timestamp': datetime.now().isoformat(),
            'summary': {
                'total_icons': len(results),
                'successful': len(successful),
                'failed': len(failed),
                'success_rate': len(successful) / len(results) * 100 if results else 0,
                'total_time': total_time,
                'average_time': avg_time
            },
            'successful_icons': [r.name for r in successful],
            'failed_icons': [{'name': r.name, 'error': r.error} for r in failed]
        }
        
        # Save report
        report_path = self.output_path / f"generation_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_path, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2)
        
        logger.info(f"Generation complete: {len(successful)}/{len(results)} successful")
        logger.info(f"Report saved: {report_path}")

async def main():
    """Main function"""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python icon_generator_v2.py <config_file.json>")
        print("Example: python icon_generator_v2.py health-app-icons.config.json")
        return 1
    
    config_file = sys.argv[1]
    
    try:
        generator = ConfigurableIconGenerator(config_file)
        results = await generator.generate_all_icons()
        
        successful = sum(1 for r in results if r.success)
        total = len(results)
        
        print(f"\n🎉 Generation complete: {successful}/{total} icons generated successfully")
        
        return 0 if successful == total else 1
        
    except Exception as e:
        logger.error(f"Generation failed: {e}")
        return 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    exit(exit_code)