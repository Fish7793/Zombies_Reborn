#include "EasyUI.as"
#define CLIENT_ONLY

EasyUI@ ui;
// const string beast_page = "zombie_beastiary_page";
// Beastiary@ beastiary;

CustomPane@[] beastiaryMenuItems;

class CustomPane : StandardPane
{
    CustomPane(EasyUI@ ui, StandardPaneType type)
    {
        super(ui, type);
    }

    CustomPane(EasyUI@ ui)
    {
        super(ui);
    }

    void SetType(StandardPaneType type)
    {
        this.type = type;
    }
}

void addBeastiaryMenuItem(Pane@ menu, string texture, Vec2f frameDim=Vec2f(32.0, 32.0), uint frameIndex=0)
{
    //todo make clickable and add a frame around the image, or change the image so it already includes a frame
    //      refactor to use event handler on hover?
    // make menu margin even on both sides
    Vec2f menuItemDim(128.0, 128.0);

    CustomPane@ menuItem = CustomPane(ui);
    menuItem.SetMinSize(menuItemDim.x, menuItemDim.y);
    menuItem.SetMaxSize(menuItemDim.x, menuItemDim.y);
    menuItem.SetMargin(10, 10);

    Icon@ menuIcon = StandardIcon();
    menuIcon.SetTexture(texture);
    menuIcon.SetMinSize(menuItemDim.x, menuItemDim.y);
    menuIcon.SetMaxSize(menuItemDim.x, menuItemDim.y);
    menuIcon.SetStretchRatio(1.0, 1.0);
    menuIcon.SetFrameDim(frameDim.x, frameDim.y);
    menuIcon.SetFrameIndex(frameIndex);
    menuIcon.SetFixedAspectRatio(false);
    beastiaryMenuItems.push_back(menuItem);

    menuItem.AddComponent(menuIcon);
    menu.AddComponent(menuItem);
}

Pane@ createBeastiaryMainPage(EasyUI@ ui)
{
    //todo: add "Beastiary title", make scrollable
    Pane@ menu = StandardPane(ui, StandardPaneType::Window);
    menu.SetAlignment(0.5f, 0.5f);
    menu.SetMaxSize(384, 512);
    menu.SetStretchRatio(1.0f, 1.0f);
    menu.SetCellWrap(3);
    menu.SetPadding(50, 50);
    ui.AddComponent(menu);
    return menu;
}

void onInit(CRules@ this)
{
    onRestart(this);
}

void onRestart(CRules@ this)
{
    @ui = EasyUI();
    Pane@ menu = createBeastiaryMainPage(ui);
    addBeastiaryMenuItem(menu, "Zombies/Greg/Greg.png");
    addBeastiaryMenuItem(menu, "Zombies/Horror/Horror.png");
    addBeastiaryMenuItem(menu, "Zombies/Skelepede/Skelepede.png", Vec2f(25.0, 25.0));
    addBeastiaryMenuItem(menu, "Zombies/Skeleton/Skeleton.png", Vec2f(25.0, 25.0));
    addBeastiaryMenuItem(menu, "Zombies/Wraith/Wraith.png");
    addBeastiaryMenuItem(menu, "Zombies/Zombie/Zombie.png", Vec2f(25.0, 25.0));
    addBeastiaryMenuItem(menu, "Zombies/ZombieKnight/ZombieKnight.png");
    // @beastiary = Beastiary(ui);

    // Label@ label = StandardLabel();
    // label.SetText("This pane is centered on the screen and stretches horizontally!");

    // Pane@ pane = StandardPane();
    // pane.SetMargin(200, 0);
    // pane.SetPadding(20, 20);
    // pane.SetAlignment(0.5f, 0.5f);
    // pane.SetStretchRatio(1.0f, 0.0f);
    // pane.SetMaxSize(600, 0);
    // pane.AddComponent(label);
    
    // Button@ button = StandardButton(ui);
    // button.SetAlignment(0.5f, 0.5f);
    // button.AddComponent(label);
    // pane.AddComponent(button);

    // ui.AddComponent(pane);
    // ui.AddComponent(button);
}

void onTick(CRules@ this)
{
    for (int i = 0; i < beastiaryMenuItems.length; i++)
    {
        CustomPane@ icon = beastiaryMenuItems[i];
        if (icon.isHovering())
        {
            icon.SetType(StandardPaneType::Sunken);
        }
        else
        {
            icon.SetType(StandardPaneType::Normal);
        }
    }
    ui.Update();
}

void onRender(CRules@ this)
{
    ui.Render();
    ui.Debug(getControls().isKeyPressed(KEY_LSHIFT));
}

//TODO: save beastiary info locally, and load it
class Beastiary
{
    u8 page;

    //probably not necessary to be members if added to ui
    Button@ next;
    Button@ previous;

    Beastiary(EasyUI@ ui)
    {
        page = 0;

        //labels for buttons
        Label@ nextLabel = StandardLabel();
        nextLabel.SetText("Next");

        Label@ previousLabel = StandardLabel();
        previousLabel.SetText("Previous");

        //buttons
        @next = StandardButton(ui);
        next.SetPadding(20, 20);
        next.SetMargin(20, 20);
        next.SetMaxSize(100, 100);
        next.AddComponent(nextLabel);

        @previous = StandardButton(ui);
        previous.SetPadding(20, 20);
        previous.SetMargin(20, 20);
        previous.SetMaxSize(100, 100);
        previous.AddComponent(previousLabel);

        //main pane texture
        Icon@ helpBackground = StandardIcon();
        helpBackground.SetTexture("HelpBackground.png");
        helpBackground.SetMinSize(341, 273);
        helpBackground.SetStretchRatio(1.0, 1.0);
        helpBackground.SetFrameDim(341, 273);
        helpBackground.SetFrameIndex(0);

        //greg
        // Icon@ icon = StandardIcon();
        // icon.SetTexture("Entities/Zombies/Greg/Greg.png");
        // icon.SetFrameDim(32, 32);
        // icon.SetFrameIndex(0);

        //main pain
        Pane@ pane = StandardPane();
        // pane.SetFlowDirection(FlowDirection::LeftUp);
        pane.SetCellWrap(2);
        // pane.SetMargin(200, 200);
        // pane.SetPadding(20, 20);
        pane.SetAlignment(0.5f, 0.5f);
        pane.SetStretchRatio(1.0f, 1.0f);
        pane.SetMaxSize(600, 600);

        pane.AddComponent(helpBackground); 
        // pane.AddComponent(next);
        // pane.AddComponent(previous);

        ui.AddComponent(pane);
    }

    void setPage(u8 page)
    {
        this.page = page;
    }

}