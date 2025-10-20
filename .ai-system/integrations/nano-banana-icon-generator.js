/**
 * Nano Banana Icon Generator Integration
 * Connects Gemini API with Nano Banana for intelligent icon generation
 * Supports batch generation, platform optimization, and style consistency
 */

const fs = require('fs').promises;
const path = require('path');
const { GoogleGenerativeAI } = require('@google/generative-ai');

class NanaBananaIconGenerator {
    constructor() {
        this.geminiApiKey = process.env.GEMINI_API_KEY;
        this.genAI = new GoogleGenerativeAI(this.geminiApiKey);
        this.model = this.genAI.getGenerativeModel({ model: "gemini-1.5-pro" });
        
        // Load project configuration
        this.projectConfig = null;
        this.envConfig = null;
        
        this.loadConfigurations();
    }

    /**
     * Load project identity and environment configurations
     */
    async loadConfigurations() {
        try {
            // Load .project-identity
            const projectIdentityPath = path.join(process.cwd(), '.project-identity');
            const projectIdentityContent = await fs.readFile(projectIdentityPath, 'utf8');
            this.projectConfig = this.parseProjectIdentity(projectIdentityContent);

            // Load .env configurations
            const envPath = path.join(process.cwd(), '.env');
            const envContent = await fs.readFile(envPath, 'utf8');
            this.envConfig = this.parseEnvConfig(envContent);

            console.log('✅ Configurations loaded successfully');
        } catch (error) {
            console.error('❌ Error loading configurations:', error.message);
        }
    }

    /**
     * Parse .project-identity file to extract relevant configuration
     */
    parseProjectIdentity(content) {
        const config = {};
        
        // Extract project colors
        const colorMatch = content.match(/projectColors:\s*\[(.*?)\]/s);
        if (colorMatch) {
            config.colors = colorMatch[1].split(',').map(c => c.trim().replace(/['"]/g, ''));
        }

        // Extract project type
        const typeMatch = content.match(/projectType:\s*["']([^"']+)["']/);
        if (typeMatch) {
            config.projectType = typeMatch[1];
        }

        // Extract personality
        const personalityMatch = content.match(/personality:\s*["']([^"']+)["']/);
        if (personalityMatch) {
            config.personality = personalityMatch[1];
        }

        return config;
    }

    /**
     * Parse .env file to extract icon generation configurations
     */
    parseEnvConfig(content) {
        const config = {};
        const lines = content.split('\n');

        lines.forEach(line => {
            if (line.includes('=') && !line.startsWith('#')) {
                const [key, value] = line.split('=', 2);
                config[key.trim()] = value.trim();
            }
        });

        return config;
    }

    /**
     * Generate single icon with Nano Banana style
     */
    async generateSingleIcon(iconRequest) {
        const {
            iconName,
            iconDescription,
            style = 'ICON_STYLE_MINIMALIST',
            platform = 'PLATFORM_UNIVERSAL',
            size = 'ICON_SIZE_GENERATION',
            colorScheme = 'COLOR_SCHEME_MONOCHROME'
        } = iconRequest;

        try {
            // Build enhanced prompt using configurations
            const prompt = this.buildIconPrompt({
                iconName,
                iconDescription,
                style,
                platform,
                size,
                colorScheme
            });

            console.log(`🎨 Generating icon: ${iconName}`);
            console.log(`📝 Prompt: ${prompt.substring(0, 100)}...`);

            // Generate with Gemini
            const result = await this.model.generateContent(prompt);
            const response = await result.response;
            const generatedText = response.text();

            // Process and save icon
            const iconData = {
                name: iconName,
                description: iconDescription,
                style: style,
                platform: platform,
                size: size,
                colorScheme: colorScheme,
                prompt: prompt,
                generatedContent: generatedText,
                timestamp: new Date().toISOString()
            };

            await this.saveIconData(iconData);
            
            console.log(`✅ Icon generated successfully: ${iconName}`);
            return iconData;

        } catch (error) {
            console.error(`❌ Error generating icon ${iconName}:`, error.message);
            throw error;
        }
    }

    /**
     * Generate batch of icons with consistent style
     */
    async generateBatchIcons(iconRequests, batchOptions = {}) {
        const {
            ensureConsistency = true,
            platform = 'PLATFORM_UNIVERSAL',
            style = 'ICON_STYLE_MINIMALIST',
            colorScheme = 'COLOR_SCHEME_MONOCHROME'
        } = batchOptions;

        console.log(`🚀 Starting batch generation of ${iconRequests.length} icons`);

        const results = [];
        const errors = [];

        // Generate style guide for consistency
        let styleGuide = '';
        if (ensureConsistency && iconRequests.length > 1) {
            styleGuide = await this.generateStyleGuide(iconRequests, { platform, style, colorScheme });
        }

        // Generate icons sequentially to maintain consistency
        for (let i = 0; i < iconRequests.length; i++) {
            const request = iconRequests[i];
            
            try {
                const iconData = await this.generateSingleIcon({
                    ...request,
                    platform: request.platform || platform,
                    style: request.style || style,
                    colorScheme: request.colorScheme || colorScheme,
                    styleGuide: styleGuide
                });

                results.push(iconData);
                
                // Progress indicator
                console.log(`📊 Progress: ${i + 1}/${iconRequests.length} icons completed`);
                
            } catch (error) {
                errors.push({
                    iconName: request.iconName,
                    error: error.message
                });
            }
        }

        // Save batch summary
        await this.saveBatchSummary(results, errors, batchOptions);

        console.log(`✅ Batch generation completed: ${results.length} successful, ${errors.length} errors`);
        
        return {
            successful: results,
            errors: errors,
            summary: {
                total: iconRequests.length,
                successful: results.length,
                failed: errors.length
            }
        };
    }

    /**
     * Generate style guide for consistent batch generation
     */
    async generateStyleGuide(iconRequests, options) {
        const iconNames = iconRequests.map(req => req.iconName).join(', ');
        
        const styleGuidePrompt = `
Create a comprehensive style guide for generating a consistent set of icons: ${iconNames}

Project Context:
- Project Type: ${this.projectConfig?.projectType || 'General'}
- Personality: ${this.projectConfig?.personality || 'Modern and clean'}
- Colors: ${this.projectConfig?.colors?.join(', ') || 'Neutral'}

Style Requirements:
- Platform: ${this.envConfig?.[options.platform] || 'Universal design'}
- Style: ${this.envConfig?.[options.style] || 'Minimalist'}
- Color Scheme: ${this.envConfig?.[options.colorScheme] || 'Monochrome'}

Generate a detailed style guide that ensures visual consistency across all icons in this set.
Include specific guidelines for:
1. Visual style and aesthetic
2. Color usage and harmony
3. Shape language and proportions
4. Level of detail and complexity
5. Platform-specific considerations

Style Guide:`;

        try {
            const result = await this.model.generateContent(styleGuidePrompt);
            const response = await result.response;
            return response.text();
        } catch (error) {
            console.warn('⚠️ Could not generate style guide, proceeding without it');
            return '';
        }
    }

    /**
     * Build enhanced prompt for icon generation
     */
    buildIconPrompt(options) {
        const {
            iconName,
            iconDescription,
            style,
            platform,
            size,
            colorScheme,
            styleGuide = ''
        } = options;

        // Get configuration values
        const basePrompt = this.envConfig?.PROMPT_GENERATE_ICON || 'Generate a modern, clean icon';
        const styleConfig = this.envConfig?.[style] || 'minimalist style';
        const platformConfig = this.envConfig?.[platform] || 'universal design';
        const sizeConfig = this.envConfig?.[size] || '512x512px';
        const colorConfig = this.envConfig?.[colorScheme] || 'monochrome';
        const qualityStandards = this.envConfig?.REQUIREMENTS_STANDARD || 'high quality, crisp edges';

        // Replace dynamic variables
        const projectColors = this.projectConfig?.colors || ['#000000'];
        const primaryColor = projectColors[0] || '#000000';
        const secondaryColor = projectColors[1] || primaryColor;
        const accentColor = projectColors[2] || primaryColor;

        let enhancedPrompt = `${basePrompt}

Icon Details:
- Name: ${iconName}
- Description: ${iconDescription}
- Style: ${styleConfig}
- Platform: ${platformConfig}
- Size: ${sizeConfig}
- Color Scheme: ${colorConfig.replace('{PRIMARY_COLOR}', primaryColor).replace('{SECONDARY_COLOR}', secondaryColor).replace('{ACCENT_COLOR}', accentColor)}

Quality Requirements: ${qualityStandards}

Project Context:
- Project Type: ${this.projectConfig?.projectType || 'General'}
- Personality: ${this.projectConfig?.personality || 'Modern'}
- Brand Colors: ${projectColors.join(', ')}`;

        if (styleGuide) {
            enhancedPrompt += `\n\nStyle Guide for Consistency:\n${styleGuide}`;
        }

        enhancedPrompt += `\n\nGenerate a detailed description for creating this icon that follows Nano Banana principles for high-quality, consistent icon generation.`;

        return enhancedPrompt;
    }

    /**
     * Save icon data to organized file structure
     */
    async saveIconData(iconData) {
        const outputDir = path.join(process.cwd(), 'generated-icons', iconData.platform.toLowerCase().replace('platform_', ''));
        await fs.mkdir(outputDir, { recursive: true });

        const filename = `${iconData.name.toLowerCase().replace(/\s+/g, '-')}-${Date.now()}.json`;
        const filepath = path.join(outputDir, filename);

        await fs.writeFile(filepath, JSON.stringify(iconData, null, 2));
        
        console.log(`💾 Icon data saved: ${filepath}`);
    }

    /**
     * Save batch generation summary
     */
    async saveBatchSummary(results, errors, batchOptions) {
        const summaryDir = path.join(process.cwd(), 'generated-icons', 'batch-summaries');
        await fs.mkdir(summaryDir, { recursive: true });

        const summary = {
            timestamp: new Date().toISOString(),
            batchOptions: batchOptions,
            results: results.map(r => ({
                name: r.name,
                style: r.style,
                platform: r.platform,
                success: true
            })),
            errors: errors,
            statistics: {
                total: results.length + errors.length,
                successful: results.length,
                failed: errors.length,
                successRate: `${((results.length / (results.length + errors.length)) * 100).toFixed(1)}%`
            }
        };

        const filename = `batch-summary-${Date.now()}.json`;
        const filepath = path.join(summaryDir, filename);

        await fs.writeFile(filepath, JSON.stringify(summary, null, 2));
        
        console.log(`📊 Batch summary saved: ${filepath}`);
    }

    /**
     * Auto-detect project type and suggest appropriate icons
     */
    async suggestProjectIcons() {
        const projectType = this.projectConfig?.projectType?.toLowerCase() || 'general';
        
        const suggestions = {
            'mobile-app': [
                { iconName: 'home', iconDescription: 'Home screen navigation icon' },
                { iconName: 'profile', iconDescription: 'User profile icon' },
                { iconName: 'settings', iconDescription: 'App settings icon' },
                { iconName: 'search', iconDescription: 'Search functionality icon' },
                { iconName: 'notifications', iconDescription: 'Push notifications icon' }
            ],
            'web-app': [
                { iconName: 'dashboard', iconDescription: 'Main dashboard icon' },
                { iconName: 'menu', iconDescription: 'Navigation menu icon' },
                { iconName: 'user', iconDescription: 'User account icon' },
                { iconName: 'logout', iconDescription: 'Sign out icon' },
                { iconName: 'help', iconDescription: 'Help and support icon' }
            ],
            'e-commerce': [
                { iconName: 'cart', iconDescription: 'Shopping cart icon' },
                { iconName: 'wishlist', iconDescription: 'Favorite items icon' },
                { iconName: 'payment', iconDescription: 'Payment method icon' },
                { iconName: 'shipping', iconDescription: 'Delivery tracking icon' },
                { iconName: 'reviews', iconDescription: 'Product reviews icon' }
            ],
            'productivity': [
                { iconName: 'tasks', iconDescription: 'Task management icon' },
                { iconName: 'calendar', iconDescription: 'Schedule and events icon' },
                { iconName: 'documents', iconDescription: 'File management icon' },
                { iconName: 'collaboration', iconDescription: 'Team collaboration icon' },
                { iconName: 'analytics', iconDescription: 'Data analytics icon' }
            ]
        };

        return suggestions[projectType] || suggestions['general'] || [
            { iconName: 'home', iconDescription: 'Home icon' },
            { iconName: 'settings', iconDescription: 'Settings icon' },
            { iconName: 'user', iconDescription: 'User icon' }
        ];
    }
}

module.exports = NanaBananaIconGenerator;

// CLI Usage Example
if (require.main === module) {
    const generator = new NanaBananaIconGenerator();
    
    // Example: Generate single icon
    // generator.generateSingleIcon({
    //     iconName: 'home',
    //     iconDescription: 'Home screen navigation icon',
    //     style: 'ICON_STYLE_MINIMALIST',
    //     platform: 'PLATFORM_IOS'
    // });

    // Example: Generate batch icons
    // const iconRequests = [
    //     { iconName: 'home', iconDescription: 'Home navigation' },
    //     { iconName: 'profile', iconDescription: 'User profile' },
    //     { iconName: 'settings', iconDescription: 'App settings' }
    // ];
    // generator.generateBatchIcons(iconRequests, {
    //     platform: 'PLATFORM_IOS',
    //     style: 'ICON_STYLE_MINIMALIST'
    // });
}