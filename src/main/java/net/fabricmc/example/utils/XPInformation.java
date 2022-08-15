// originally from https://github.com/Moulberry/NotEnoughUpdates
// shortened, adapted for fabric
package net.fabricmc.example.utils;

import net.fabricmc.example.ExampleMod;

import net.minecraft.util.StringHelper;

import com.google.common.base.Splitter;

import java.util.HashMap;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class XPInformation {
	private static final XPInformation INSTANCE = new XPInformation();

    /**
     * The amount of usable tickers or -1 if none are in the action bar.
     */
    public static int tickers = -1;

    /**
     * The total amount of possible tickers or 0 if none are in the action bar.
     */
    public static int maxTickers = 0;

	public static XPInformation getInstance() {
		return INSTANCE;
	}

	public static class SkillInfo {
		public int level;
		public float deltaXp;
		public float currentXp;
		public float currentXpMax;
	}

	private final HashMap<String, SkillInfo> initials = new HashMap<>();
	private final HashMap<String, SkillInfo> skillInfoMap = new HashMap<>();
	public HashMap<String, Float> updateWithPercentage = new HashMap<>();

	private static final Splitter SPACE_SPLITTER = Splitter.on("  ").omitEmptyStrings().trimResults();
	private static final Pattern SKILL_PATTERN = Pattern.compile(
		"\\+(\\d+(?:,\\d+)*(?:\\.\\d+)?) (.+) \\((\\d+(?:,\\d+)*(?:\\.\\d+)?)/(\\d+(?:,\\d+)*(?:\\.\\d+)?)\\)");
	private static final Pattern SKILL_PATTERN_MULTIPLIER =
		Pattern.compile("\\+(\\d+(?:,\\d+)*(?:\\.\\d+)?) (.+) \\((\\d+(?:,\\d+)*(?:\\.\\d+)?)/(\\d+(?:k|m|b))\\)");
	private static final Pattern SKILL_PATTERN_PERCENTAGE =
		Pattern.compile("\\+(\\d+(?:,\\d+)*(?:\\.\\d+)?) (.+) \\((\\d\\d?(?:\\.\\d\\d?)?)%\\)");

	public HashMap<String, SkillInfo> getSkillInfoMap() {
		return skillInfoMap;
	}

    public static String cleanColour(String in) {
        return in.replaceAll("(?i)\\u00A7.", "");
    }

    private String lastActionBar = null;

    public void onChatReceived(String msg) {
        String actionBar = cleanColour(StringHelper.stripTextFormat(msg));

        if (lastActionBar != null && lastActionBar.equalsIgnoreCase(actionBar)) {
            return;
        }
        lastActionBar = actionBar;

        List<String> components = SPACE_SPLITTER.splitToList(msg);
        String skillS = null;
        SkillInfo skillInfo = null;

        for (String component : components) {
            if (component.contains("Ⓞ") || component.contains("ⓩ")) {
                parseTickers(component);
            }
        }

        for (String component : components) {
            if ( component.startsWith("§3" ))
                component = component.substring(2);
            Matcher matcher = SKILL_PATTERN.matcher(component);
            if (matcher.matches()) {
                String deltaXpS = matcher.group(1).replace(",", "");
                skillS = matcher.group(2);
                String currentXpS = matcher.group(3).replace(",", "");
                String maxXpS = matcher.group(4).replace(",", "");

                skillInfo = new SkillInfo();
                skillInfo.deltaXp = Float.parseFloat(deltaXpS);
                skillInfo.currentXp = Float.parseFloat(currentXpS);
                skillInfo.currentXpMax = Float.parseFloat(maxXpS);
                break;
            } else {
                matcher = SKILL_PATTERN_PERCENTAGE.matcher(component);
                if (matcher.matches()) {
                    skillS = matcher.group(2);
                    String xpPercentageS = matcher.group(3).replace(",", "");

                    float xpPercentage = Float.parseFloat(xpPercentageS);
                    updateWithPercentage.put(skillS, xpPercentage);
                } else {
                    matcher = SKILL_PATTERN_MULTIPLIER.matcher(component);

                    if (matcher.matches()) {
                        String deltaXpS = matcher.group(1).replace(",", "");
                        skillS = matcher.group(2);
                        String currentXpS = matcher.group(3).replace(",", "");
                        String maxXpS = matcher.group(4).replace(",", "");

                        float maxMult = 1;
                        if (maxXpS.endsWith("k")) {
                            maxMult = 1000;
                            maxXpS = maxXpS.substring(0, maxXpS.length() - 1);
                        } else if (maxXpS.endsWith("m")) {
                            maxMult = 1000000;
                            maxXpS = maxXpS.substring(0, maxXpS.length() - 1);
                        } else if (maxXpS.endsWith("b")) {
                            maxMult = 1000000000;
                            maxXpS = maxXpS.substring(0, maxXpS.length() - 1);
                        }

                        skillInfo = new SkillInfo();
                        skillInfo.deltaXp = Float.parseFloat(deltaXpS);
                        skillInfo.currentXp = Float.parseFloat(currentXpS);
                        skillInfo.currentXpMax = Float.parseFloat(maxXpS) * maxMult;
                        break;
                    }
                }
            }
        }
        if ( skillInfo != null ) {
            SkillInfo prev = skillInfoMap.get(skillS);
            if ( prev != null ) {
                skillInfo.deltaXp += prev.deltaXp;
            }
            skillInfoMap.put(skillS, skillInfo);
        }
    }

    // from https://github.com/BiscuitDevelopment/SkyblockAddons
    /**
     * Parses the ticker section and updates {@link #tickers} and {@link #maxTickers} accordingly.
     * {@link #tickers} being usable tickers and {@link #maxTickers} being the total amount of possible tickers.
     *
     * @param tickerSection Ticker section of the action bar
     * @return null or {@code tickerSection} if the ticker display is disabled
     */
    private void parseTickers(String tickerSection) {
        // Zombie with full charges: §a§lⓩⓩⓩⓩ§2§l§r
        // Zombie with one used charges: §a§lⓩⓩⓩ§2§lⓄ§r
        // Scorpion tickers: §e§lⓄⓄⓄⓄ§7§l§r
        // Ornate: §e§lⓩⓩⓩ§6§lⓄⓄ§r

        // Zombie uses ⓩ with color code a for usable charges, Ⓞ with color code 2 for unusable
        // Scorpion uses Ⓞ with color code e for usable tickers, Ⓞ with color code 7 for unusable
        // Ornate uses ⓩ with color code e for usable charges, Ⓞ with color code 6 for unusable
        tickers = 0;
        maxTickers = 0;
        boolean hitUnusables = false;
        for (char character : tickerSection.toCharArray()) {
            if (!hitUnusables && (character == '7' || character == '2' || character == '6')) {
                // While the unusable tickers weren't hit before and if it reaches a grey(scorpion) or dark green(zombie)
                // or gold (ornate) color code, it means those tickers are used, so stop counting them.
                hitUnusables = true;
            } else if (character == 'Ⓞ' || character == 'ⓩ') { // Increase the ticker counts
                if (!hitUnusables) {
                    tickers++;
                }
                maxTickers++;
            }
        }
    }
}
